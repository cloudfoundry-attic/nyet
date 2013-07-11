require "net/http"
require "support/test_app"

module ManageServiceHelpers
  def it_can_manage_service(options={})
    app_name = options[:app_name] || raise("Missing app_name")
    namespace = options[:namespace] || raise("Missing namespace")
    plan_name = options[:plan_name] || raise("Missing plan_name")
    service_name = options[:service_name] || raise("Missing service_name")
    instance_name = "#{app_name}_#{plan_name}"
    host = "services-nyets-#{app_name}"

    describe "manage service" do
      with_user_with_org
      with_shared_space

      let(:dog_tags) { {service: app_name} }
      let(:test_app_path) { "../../../apps/ruby/app_sinatra_service" }

      it "allows users to create, bind, read, write, unbind, and delete the #{app_name} service" do
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

            test_app.insert_value('key', 'value').should be_a Net::HTTPSuccess
            test_app.get_value('key').should == 'value'
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
  end
end

RSpec.configure do |config|
  config.extend(ManageServiceHelpers)
end
