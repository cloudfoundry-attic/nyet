shared_examples_for "A bindable service" do |app_name|
  let(:user) { RegularUser.from_env }
  let!(:org) { user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME")) }
  let!(:space) do
    SharedSpace.instance { user.create_space(org) }
  end

  let(:dog_tags) { {service: app_name} }
  let(:test_app_path) { "../../../apps/ruby/app_sinatra_service" }

  it "allows users to create, bind, read, write, unbind, and delete the #{app_name} service" do
    plan = user.find_service_plan(service_name, plan_name)
    plan.should be

    service_instance = nil
    binding = nil
    test_app = nil

    app = user.create_app(space, app_name)
    route = user.create_route(app, "#{app_name}-#{SecureRandom.hex(2)}")

    begin
      monitoring.record_action("create_service", dog_tags) do
        service_instance = user.create_service_instance(space, service_name, plan_name)
        service_instance.guid.should be
      end

      monitoring.record_action("bind_service", dog_tags) do
        binding = user.bind_service_to_app(service_instance, app)
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

    binding.delete!
    service_instance.delete!
    app.delete!
  end
end