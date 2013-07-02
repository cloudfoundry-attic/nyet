require 'spec_helper'
require 'support/test_app'

describe 'Managing Dummy', :only_in_staging => true do
  let(:namespace) { "dummy-dev" }
  let(:plan_name) { "small" }
  let(:service_name) { "dummy-dev" }
  let(:app_name) { 'dummy' }


  let(:user) { RegularUser.from_env }
  let!(:org) { user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME")) }
  let!(:space) { user.create_space(org) }
  let(:dog_tags) { {service: 'dummy'} }
  let(:test_app_path) { "../../../apps/ruby/app_sinatra_service" }

  after do
    monitoring.record_action(:delete, dog_tags) do
      space.delete!(:recursive => true)
    end
  end

  it "allows users to create, bind, unbind, and delete the dummy service" do
    plan = user.find_service_plan(service_name, plan_name)
    plan.should be

    service_instance = nil
    binding = nil

    app = user.create_app(space, app_name)

    monitoring.record_action("create_service", dog_tags) do
      service_instance = user.create_service_instance(space, service_name, plan_name)
      service_instance.guid.should be
    end

    monitoring.record_action("bind_service", dog_tags) do
      binding = user.bind_service_to_app(service_instance, app)
      binding.guid.should be
    end

    binding.delete!
    service_instance.delete!
    app.delete!
  end
end