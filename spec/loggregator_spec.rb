require "spec_helper"
require "net/http"
require "securerandom"
require "timeout"
require "support/test_env"
require "support/app_crud_helpers"

describe "Loggregator", component: 'loggregator' do
  include AppCrudHelpers

  with_user_with_org
  with_new_space
  with_time_limit

  let(:app_content) { "#{SecureRandom.uuid}_#{Time.now.to_i}" }
  let(:language) { ENV["NYET_APP"] || "java" }
  let(:app_name) { "crud-#{language}" }
  attr_reader :route

  it "gets log messages from an app" do
    begin
      regular_user.clean_up_app_from_previous_run(app_name)
      @app = regular_user.create_app(@space, app_name, CUSTOM_VAR: app_content)

      regular_user.clean_up_route_from_previous_run(app_name)
      @route = regular_user.create_route(@app, app_name, TestEnv.default.apps_domain)

      if path = APPS[language]
        deploy_app(@app, path)
      else
        raise "NYET_APP was set to #{ENV["NYET_APP"].inspect}, must be one of #{APPS.keys.to_s} (or nil)"
      end

      start_app_and_wait_until_up(@app)

      monitoring.record_action(:loggregator_works) do
        initialize_gcf
        check_loggregator_works
      end

      @route.delete!
      @app.delete!

      monitoring.record_metric("loggregator.health", 1)
    rescue => e
      monitoring.record_metric("loggregator.health", 0)
      raise e
    end
  end

  def check_loggregator_works
    puts "starting #{__method__} (#{Time.now})"

    BlueShell::Runner.run("gcf logs #{app_name}") do |runner|
      runner.with_timeout 60 do
        runner.should say "Connected, tailing logs for app #{app_name}"
      end

      # Hit twice to see that both router and app messages come through; order is not guaranteed
      runner.with_timeout 60 do
        page_content
        runner.should say "[RTR]"
      end

      runner.with_timeout 60 do
        page_content
        runner.should say "[App/0]"
      end
    end
  end


  def initialize_gcf
    username = ENV['NYET_REGULAR_USERNAME']
    password = ENV['NYET_REGULAR_PASSWORD']
    api_endpoint = ENV['NYET_TARGET']

    `gcf api #{api_endpoint}`
    `gcf auth #{username} #{password}`
    `gcf target -o #{@org.name} -s #{@space.name}`
  end
end
