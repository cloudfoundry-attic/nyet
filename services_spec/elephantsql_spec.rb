require 'spec_helper'
require 'net/http'
require 'timeout'

class TestApp
  attr_reader :host_name, :service_instance, :app
  WAITING_TIMEOUT = 300.freeze

  def initialize(app, host_name, service_instance)
    @app = app
    @host_name = host_name
    @service_instance = service_instance
  end

  def insert_value(key, value)
    http = Net::HTTP.new(host_name)
    http.post(key_path(key), value)
  end

  def get_value(key)
    http = Net::HTTP.new(host_name)
    http.get(key_path(key)).body
  end

  def when_running(&block)
    Timeout::timeout(WAITING_TIMEOUT) do
      printf "\nWaiting for app"
      loop do
        begin
          if app.running?
            break
          end
        rescue CFoundry::NotStaged
        end
        sleep 1
        printf '.'
      end
    end
    block.call
  end

  private
  def key_path(key)
    "/service/#{service_instance.name}/#{key}"
  end
end

describe 'Managing ElephantSQL' do
  let(:user) { RegularUser.from_env }
  let(:app_name) { 'elephantsql' }
  let!(:org) { user.find_organization_by_name(ENV.fetch("NYET_ORGANIZATION_NAME")) }
  let!(:space) { user.create_space(org) }

  after do
    monitoring.record_action(:delete) do
      space.delete!(:recursive => true)
    end
  end

  it 'allows users to create, bind, unbind, and delete ElephantSQL service' do
    plan = user.find_service_plan('elephantsql-dev', 'turtle')
    plan.should be

    service_instance = nil
    monitoring.record_action(:create) do
      service_instance = user.create_service_instance(space, 'elephantsql-dev', 'turtle')
    end
    service_instance.guid.should be

    app = user.create_app(space, app_name)
    binding = user.bind_service_to_app(service_instance, app)
    binding.guid.should be

    route = user.create_route(app, "#{app_name}-#{SecureRandom.hex(2)}")
    app.upload(File.expand_path("../../apps/ruby/app_sinatra_service", __FILE__))
    monitoring.record_action(:start) do
      app.start!(true)
    end

    test_app = TestApp.new(app, route.name, service_instance)
    test_app.when_running do
      test_app.insert_value('key', 'value')
      test_app.get_value('key').should == 'value'
    end

    binding.delete!
    service_instance.delete!
    app.delete!
  end
end