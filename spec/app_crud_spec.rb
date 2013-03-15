require 'spec_helper'
require 'timeout'

Bundler.require(:default)

describe 'App CRUD' do
  let(:client) { logged_in_client }
  let(:app_name) { 'crud' }
  before do
    app = client.app_by_name(app_name)
    app.delete! if app

    route = client.route_by_host(app_name)
    route.delete! if route
  end

  it 'can CRUD(ish): push, curl, update, delete the app' do
    app = client.app
    app.name = app_name
    app.memory = 64
    app.total_instances = 1
    org = client.organization_by_name(org_name)
    app.space = org.space_by_name(space_name)
    app.create!

    route = client.route
    route.host = app_name
    route.domain = app.space.domains.first
    route.space = app.space

    route.create!

    app.add_route(route)

    app.upload(app_path('ruby', 'simple'))

    app.start!(true)

    Timeout::timeout(90) do
      until app.instances.first.state == 'RUNNING'
        puts 'check for running'
        sleep 1
      end
    end

    expect(HTTParty.get("http://#{route.host}.#{route.domain.name}").body).to eq('hi')

    #update the app by scaling instances to two
    app.total_instances = 2
    app.update!
    expect(app.total_instances).to eq(2)
    expect(app.instances.map(&:state).uniq).to eq(['RUNNING'])

    app.delete!
    expect(HTTParty.get("http://#{route.host}.#{route.domain.name}")).not_to be_success
    route.delete!
  end
end