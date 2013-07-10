require "spec_helper"

describe "Managing Dummy", :only_in_staging => true, :appdirect => true do
  let(:namespace) { "dummy-dev" }
  let(:plan_name) { "small" }
  let(:service_name) { "dummy-dev" }
  let(:app_name) { 'dummy' }

  let(:dog_tags) { {service: 'dummy'} }
  let(:test_app_path) { "../../../apps/ruby/app_sinatra_service" }

  with_user_with_org
  with_shared_space

  it "allows users to create, bind, unbind, and delete the dummy service" do
    begin
      puts "Space guid is #{space.guid}"
      plan = regular_user.find_service_plan(service_name, plan_name)
      plan.should be

      service_instance = nil
      binding = nil

      app = regular_user.create_app(space, app_name)

      monitoring.record_action("create_service", dog_tags) do
        service_instance = regular_user.create_service_instance(space, service_name, plan_name)
        service_instance.guid.should be
      end

      monitoring.record_action("bind_service", dog_tags) do
        binding = regular_user.bind_service_to_app(service_instance, app)
        binding.guid.should be
      end
    ensure
      binding.delete!          if binding
      service_instance.delete! if service_instance
      app.delete!              if app
    end
  end
end
