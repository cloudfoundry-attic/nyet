require 'timeout'

class TestApp
  attr_reader :host_name, :service_instance, :app
  # temporarily bumping this to 10mins
  # sunset this after the HM fix
  WAITING_TIMEOUT = 600

  def initialize(app, host_name, service_instance, namespace)
    @app = app
    @host_name = host_name
    @service_instance = service_instance
    @namespace = namespace
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
    "/service/#{@namespace}/#{service_instance.name}/#{key}"
  end
end
