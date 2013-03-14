require 'spec_helper'
require 'timeout'

Bundler.require(:default)

describe 'App CRUD' do
  let(:client) { logged_in_client }
  it 'can push the app without an error' do
    app = client.app
    app.name = 'crud'
    app.memory = 64
    app.total_instances = 1
    app.space = client.space_by_name('test')
    app.create!

    route = client.route
    route.host = 'crud'
    route.domain = app.space.domains.first
    route.space = app.space

    route.create!

    app.add_route(route)

    app.upload(app_path('ruby', 'simple'))

    app.start!(true)

    Timeout::timeout(90) do
      until app.instances.first.state == 'RUNNING'
        puts 'check'
        sleep 1
      end
    end

    HTTParty.get("http://#{route.host}.#{route.domain.name}").body.should == 'hi'
  end
end