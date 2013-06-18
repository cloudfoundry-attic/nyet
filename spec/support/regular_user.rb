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
      app.memory = 512
      app.total_instances = 1
      app.space = space
      app.create!
    end)
  end

  def create_service_instance(space, service_label, plan_name)
    service_plan = find_service_plan(service_label, plan_name)
    debug(:create, client.service_instance.tap do |service_instance|
      service_instance.name = "#{service_plan.name}-#{SecureRandom.uuid}"
      service_instance.service_plan = service_plan
      service_instance.space = space
      service_instance.create!
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

  def find_service_plan(service_label, plan_name)
    find_service(service_label).service_plans.detect { |p| p.name == plan_name } or raise "No plan named #{plan_name.inspect}"
  end

  private
  def debug(action, object)
    puts "--- #{action}: #{object.inspect} (regular user: #{client.current_user.inspect})"
    object
  end

  def client
    @client ||= CFoundry::Client.new(@target.to_s).tap do |c|
      c.login(@username, @password)
    end
  end

  def find_service(service_label)
    client.services.detect { |s| s.label == service_label } or raise "No service named #{service_label.inspect}"
  end
end
