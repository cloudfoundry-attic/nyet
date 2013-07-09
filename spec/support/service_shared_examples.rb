require "support/app_with_start"
require "support/app_with_service"

module ManageServiceHelpers
  def it_can_manage_service(options={})
    app_name     = options[:app_name]     || raise("Missing app_name")
    namespace    = options[:namespace]    || raise("Missing namespace")
    plan_name    = options[:plan_name]    || raise("Missing plan_name")
    service_name = options[:service_name] || raise("Missing service_name")

    describe "manage service" do
      with_user_with_org
      with_shared_space

      with_health_monitoring "services.health"
      with_tagged_monitoring service: app_name

      before { regular_user.find_service_plan(service_name, plan_name) }

      before { @app = regular_user.create_app(space, app_name) }
      after { @app.delete! if @app }

      before { @route = regular_user.create_route(@app) }
      after { @route.delete! if @route }

      it "creates/binds/reads/writes/unbinds/deletes a service" do
        monitoring.record_action(:create_service) do
          @service_instance = \
            regular_user.create_service_instance(space, service_name, plan_name)
        end

        monitoring.record_action(:bind_service) do
          @service_binding = \
            regular_user.bind_service_to_app(@service_instance, @app)
        end

        deploy_and_start_app(@app)

        monitoring.record_action(:check_service) do
          check_service_persists(@app, @service_instance, namespace)
        end

        monitoring.record_action(:delete_service) do
          @service_binding.delete!
          @service_instance.delete!
        end
      end

      def deploy_and_start_app(app)
        app.upload(File.expand_path("../../../apps/ruby/app_sinatra_service", __FILE__))
        AppWithStart.new(app, 600, 2).start_and_wait
      rescue => e
        raise if ENV["NYET_RAISE_ALL_ERRORS"]
        pending "Unable to push an app. Possibly backend issue, error #{e.inspect}"
      end

      def check_service_persists(app, service_instance, namespace)
        aws = AppWithService.new(app, service_instance, namespace)
        aws.get_env
        aws.insert_value("key", "value")
        aws.get_value("key").should == "value"
      end
    end
  end
end

RSpec.configure do |config|
  config.extend(ManageServiceHelpers)
end
