require 'spec_helper'

describe 'Managing BlazeMeter' do
  let(:user) { RegularUser.from_env }
  let!(:org) { user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME")) }
  let!(:space) { user.create_space(org) }

  after do
    monitoring.record_action(:delete) do
      space.delete!(:recursive => true)
    end
  end

  it 'allows users to create, bind, read, write, unbind, and delete the BlazeMeter service' do
    plan = user.find_service_plan('blazemeter', 'free-tier')
    plan.should be

    service_instance = nil
    monitoring.record_action(:create) do
      service_instance = user.create_service_instance(space, 'blazemeter', 'free-tier')
    end
    service_instance.guid.should be

    service_instance.delete!
  end
end
