require 'spec_helper'

describe 'Managing ElephantSQL' do
  let(:user) { RegularUser.from_env }

  before do
    @org = user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME"))
    @space = user.create_space(@org)
  end

  after { @space.delete!(:recursive => true) }

  it 'allows users to create, bind, unbind, and delete ElephantSQL service' do
    plan = user.find_service_plan('elephantsql-dev', 'turtle')
    plan.should be

    monitoring.record_action(:create) do
      user.create_service_instance(@space, 'elephantsql-dev', 'turtle').should be
    end
  end
end