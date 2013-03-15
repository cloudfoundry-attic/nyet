require 'bundler'

Bundler.require(:default)

module NyetHelpers
  def logged_in_client
    username = ENV['NYET_USERNAME']
    password = ENV['NYET_PASSWORD']
    target = ENV['NYET_TARGET']

    client = CFoundry::Client.new(target)
    client.login(username, password)

    client
  end

  def app_path(*parts)
    File.expand_path(File.join(File.dirname(__FILE__), '..',  'apps', *parts))
  end

  def with_model(model)
    model.create!
    yield
  ensure
    model.delete!
  end

  def clean_up_previous_run(client, name)
    app = client.app_by_name(name)
    app.delete! if app

    route = client.route_by_host(name)
    route.delete! if route
  end
end