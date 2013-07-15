require "spec_helper"

describe "Managing SendGrid", :appdirect => true do
  let(:app_name) { "sendgrid" }
  let(:namespace) { "smtp" }
  let(:plan_name) { "free" }
  let(:service_name) { "sendgrid-dev" }
  let(:instance_name) { "#{app_name}_#{plan_name}" }
  let(:host) { "services-nyets-#{app_name}" }

  with_user_with_org
  with_shared_space

  let(:dog_tags) { {service: app_name} }
  let(:test_app_path) { File.join(File.dirname(__FILE__), "../apps/ruby/app_sinatra_service") }

  it "allows users to create, bind, send emails, unbind, and delete the SendGrid service" do
    begin
      regular_user.clean_up_app_from_previous_run(app_name)
      regular_user.clean_up_service_instance_from_previous_run(instance_name)
      regular_user.clean_up_route_from_previous_run(host)

      plan = regular_user.find_service_plan(service_name, plan_name)
      plan.should be

      service_instance = nil
      binding = nil
      test_app = nil

      app = regular_user.create_app(space, app_name)
      route = regular_user.create_route(app, host)

      begin
        monitoring.record_action("create_service", dog_tags) do
          service_instance = regular_user.create_service_instance(space, service_name, plan_name, instance_name)
          service_instance.guid.should be
        end

        monitoring.record_action("bind_service", dog_tags) do
          binding = regular_user.bind_service_to_app(service_instance, app)
          binding.guid.should be
        end

        begin
          app.upload(File.expand_path(test_app_path, __FILE__))
          monitoring.record_action(:start, dog_tags) do
            app.start!(true)
            test_app = TestApp.new(app, route.name, service_instance, namespace)
            test_app.when_running
          end
        rescue => e
          raise if ENV["NYET_RAISE_ALL_ERRORS"]
          pending "Unable to push an app. Possibly backend issue, error #{e.inspect}"
        end

        test_app.get_env
        test_app.send_email("john@example.com").should be_a Net::HTTPSuccess

        monitoring.record_metric("services.health", 1, dog_tags)
      rescue RSpec::Core::Pending::PendingDeclaredInExample => e
        raise e
      rescue => e
        monitoring.record_metric("services.health", 0, dog_tags)
        raise e
      end
    ensure
      regular_user.clean_up_app_from_previous_run(app_name)
      regular_user.clean_up_service_instance_from_previous_run(instance_name)
      regular_user.clean_up_route_from_previous_run(host)
    end

  end
end
