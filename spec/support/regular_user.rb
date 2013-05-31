require "uri"
require "securerandom"
require "cfoundry"

class RegularUser
  def self.from_env
    new(*%w(NYET_TARGET NYET_REGULAR_USERNAME NYET_REGULAR_PASSWORD).map do |var|
      ENV[var] || raise(ArgumentError, "missing #{var}")
    end)
  end

  def initialize(target, username, password)
    @target = URI(target)
    @username = username
    @password = password
  end

  attr_reader :client

  def user
    debug(:find, client.current_user)
  end

  def find_organization_by_name(name)
    debug(:find, client.organization_by_name(name).tap do |org|
      raise "failed to find organization '#{name}'" unless org
    end)
  end

  def create_space(org)
    debug(:create, client.space.tap do |space|
      space.name = "nyet-space-#{SecureRandom.uuid}"
      space.organization = org
      space.developers = [client.current_user]
      space.create!
    end)
  end

  def create_app(space, name)
    debug(:create, client.app.tap do |app|
      app.name = name
      app.memory = 256
      app.total_instances = 1
      app.space = space
      app.create!
    end)
  end

  def clean_up_app_from_previous_run(name)
    if app = client.app_by_name(name)
      debug(:delete, app)
      app.delete!(recursive: true)
    end
  end

  def create_route(app, host)
    debug(:create, client.route.tap do |route|
      route.host = host
      route.domain = app.space.domains.first
      route.space = app.space
      route.create!
      app.add_route(route)
    end)
  end

  def clean_up_route_from_previous_run(host)
    if route = client.route_by_host(host)
      debug(:delete, route)
      route.delete!(recursive: true)
    end
  end

  private

  def debug(action, object)
    puts "--- #{action}: #{object.inspect} (regular user)"
    object
  end

  def client
    @client ||= CFoundry::Client.new(@target.to_s).tap do |c|
      c.login(@username, @password)
    end
  end
end
