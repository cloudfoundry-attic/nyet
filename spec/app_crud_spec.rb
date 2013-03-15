require 'timeout'
require 'nyet_helpers'

Bundler.require(:default)

describe 'App CRUD' do
  include NyetHelpers

  let(:client) { logged_in_client }
  let(:app_name) { 'crud' }

  let(:org_name) do
    "org-#{SecureRandom.uuid}"
  end

  let(:space_name) do
    "space-#{SecureRandom.uuid}"
  end

  around do |example|
    clean_up_previous_run(client, app_name)

    org = client.organization
    org.name = org_name
    with_model(org) do
      space = client.space
      space.name = space_name
      space.organization = org
      with_model(space) do
        example.run
      end
    end

    expect(client.organization_by_name(org_name)).to be_nil
    expect(client.space_by_name(space_name)).to be_nil
  end

  it 'can CRUD' do
    extend AppCrud
    create
    read
    update
    delete
  end

  module AppCrud
    attr_accessor :app, :route
    def create
      @app = client.app
      app.name = app_name
      app.memory = 64
      app.total_instances = 1
      org = client.organization_by_name(org_name)
      app.space = org.space_by_name(space_name)
      app.create!

      @route = client.route
      route.host = app_name
      route.domain = app.space.domains.first
      route.space = app.space

      route.create!

      app.add_route(route)

      app.upload(app_path('ruby', 'simple'))

      app.start!(true)

      Timeout::timeout(90) do
        until app.instances.first.state == 'RUNNING'
          sleep 0.5
        end
      end
    end

    def read
      expect(HTTParty.get("http://#{route.host}.#{route.domain.name}").body).to eq('hi')
    end

    def update
      #update the app by scaling instances to two
      app.total_instances = 2
      app.update!
      expect(app.total_instances).to eq(2)
      expect(app.instances.map(&:state).uniq).to eq(['RUNNING'])
    end

    def delete
      app.delete!
      expect(HTTParty.get("http://#{route.host}.#{route.domain.name}")).not_to be_success
      route.delete!
    end
  end
end