require "spec_helper"
require "timeout"
require "net/http"
require "securerandom"
require "support/app_with_start"

describe "App CRUD" do
  CHECK_DELAY = 0.5.freeze
  APP_START_TIMEOUT = 120.freeze
  APP_ROUTE_TIMEOUT = 5.freeze
  APP_SCALE_TIMEOUT = 60.freeze
  APP_DELETED_TIMEOUT = 60.freeze

  with_user_with_org
  with_new_space

  with_health_monitoring "crud_app.health"

  it "creates/updates/deletes an app" do
      monitoring.record_action(:create) do
        app_name = "crud"

        regular_user.clean_up_app_from_previous_run(app_name)
        @app = regular_user.create_app(@space, app_name)

        regular_user.clean_up_route_from_previous_run(app_name)
        @route = regular_user.create_route(@app)
      end

      monitoring.record_action(:push) do
        deploy_app(@app)
      end

      monitoring.record_action(:start) do
        AppWithStart.new(@app, APP_START_TIMEOUT, CHECK_DELAY).start_and_wait
      end

      monitoring.record_action(:app_routable) do
        check_app_routable(@route)
      end

      monitoring.record_action(:update) do
        scale_app(@app)
      end

      monitoring.record_action(:delete) do
        @route.delete!
        @app.delete!
        check_app_not_running(@route)
      end
  end

  def deploy_app(app)
    app.upload(File.expand_path("../../apps/java/JavaTinyApp-1.0.war", __FILE__))
  end

  def check_app_routable(route)
    app_uri = URI("http://#{route.host}.#{route.domain.name}")
    content = nil
    Timeout.timeout(APP_ROUTE_TIMEOUT) do
      content = Net::HTTP.get(app_uri)
    end
    expect(content).to match(/^It just needed to be restarted!/)
  end

  def scale_app(app)
    app.total_instances = 2
    app.update!

    Timeout.timeout(APP_SCALE_TIMEOUT) do
      sleep(CHECK_DELAY) until app.running?
    end
  end

  def check_app_not_running(route)
    app_uri = URI("http://#{route.name}")

    Timeout.timeout(APP_DELETED_TIMEOUT) do
      response = Net::HTTP.get_response(app_uri)
      puts "--- GET #{app_uri}: #{response.class}"

      while response.is_a?(Net::HTTPSuccess)
        puts "--- GET #{app_uri}: #{response.class}"
        sleep(CHECK_DELAY)
        response = Net::HTTP.get_response(app_uri)
      end
    end
  end
end
