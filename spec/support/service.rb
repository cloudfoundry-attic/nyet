require "support/test_env"

module ServiceHelper
  def self.included(base)
    base.instance_eval do
      let(:namespace) { nil }
      let(:instance_name) { "#{app_name}_service_instance" }
      let(:host) { "services-nyets-#{app_name}" }

      with_user_with_org
      with_shared_space

      let(:dog_tags) { {service: app_name} }
      let(:test_app_path) { File.join(File.dirname(__FILE__), "../../apps/ruby/app_sinatra_service") }

      before do
        regular_user.clean_up_app_from_previous_run(app_name)
        regular_user.clean_up_service_instance_from_previous_run(space, instance_name)
        regular_user.clean_up_route_from_previous_run(host)

        @app_signature = SecureRandom.uuid
        @app = regular_user.create_app(space, app_name, {APP_SIGNATURE: @app_signature})
        @route = regular_user.create_route(@app, host, TestEnv.default.apps_domain)
      end

      after do
        regular_user.clean_up_app_from_previous_run(app_name)
        regular_user.clean_up_service_instance_from_previous_run(space, instance_name)
        regular_user.clean_up_route_from_previous_run(host)
      end
    end
  end

  def create_and_use_managed_service(&blk)
    service_instance = nil
    monitoring.record_action("create_service", dog_tags) do
      service_instance = regular_user.create_managed_service_instance(space, service_name, plan_name, instance_name)
      service_instance.guid.should be
    end

    monitoring.record_action("bind_service", dog_tags) do
      binding = regular_user.bind_service_to_app(service_instance, @app)
      binding.guid.should be
    end

    test_app = nil

    begin
      @app.upload(File.expand_path(test_app_path, __FILE__))
      monitoring.record_action(:start, dog_tags) do
        @app.start!
        test_app = TestApp.new(
          app: @app,
          host_name: @route.name,
          service_instance: service_instance,
          namespace: namespace,
          example: self,
          signature: @app_signature
        )
        test_app.wait_until_running
      end
    rescue => e
      raise if ENV["NYET_RAISE_ALL_ERRORS"]
      pending "Unable to push an app. Possibly backend issue, error #{e.inspect}"
    end

    blk.call(test_app)

    monitoring.record_metric("services.health", 1, dog_tags)
  rescue CFoundry::APIError => e
    monitoring.record_metric("services.health", 0, dog_tags)
    puts '--- CC error:'
    puts '<<<'
    puts e.request_trace
    puts '>>>'
    puts e.response_trace
    raise
  rescue RSpec::Core::Pending::PendingDeclaredInExample => e
    raise e
  rescue => e
    monitoring.record_metric("services.health", 0, dog_tags)
    raise e
  end
end

RSpec.configure do |config|
  config.include(ServiceHelper, :service => true)
end
