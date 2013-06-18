require 'spec_helper'

describe 'Managing ElephantSQL' do
  let(:user) { RegularUser.from_env }
  let(:app_name) { 'elephantsql' }
  let!(:org) { user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME")) }
  let!(:space) { user.create_space(org) }

  after { space.delete!(:recursive => true) }

  it 'allows users to create, bind, unbind, and delete ElephantSQL service' do
    plan = user.find_service_plan('elephantsql-dev', 'turtle')
    plan.should be

    service_instance = nil
    monitoring.record_action(:create) do
      service_instance = user.create_service_instance(space, 'elephantsql-dev', 'turtle')
    end
    service_instance.should be

    app = user.create_app(space, app_name)
    binding = user.bind_service_to_app(service_instance, app)
    binding.should be

    # route = user.create_route(app, "#{app_name}-#{SecureRandom.hex(2)}")
    # app.upload(File.expand_path("../../apps/java/JavaTinyApp-1.0.war", __FILE__))
    binding.delete!
    service_instance.delete!
    app.delete!
  end
end