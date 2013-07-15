require 'timeout'
require 'cgi'

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

  def get_env
    http = Net::HTTP.new(host_name)
    path = "/env"
    debug("GET from #{host_name} #{path}")
    response = http.get(path)
    debug("Response: #{response}")
    debug("  Body: #{response.body}")
    response.body
  end

  def insert_value(key, value)
    http = Net::HTTP.new(host_name)
    key_path = key_path(key)
    debug("POST to #{host_name} #{key_path}")
    response = http.post(key_path, value)
    debug("Response: #{response}")
    debug("  Body: #{response.body}")
    response
  end

  def get_value(key)
    http = Net::HTTP.new(host_name)
    key_path = key_path(key)
    debug("GET from #{host_name} #{key_path}")
    response = http.get(key_path)
    debug("Response: #{response}")
    debug("  Body: #{response.body}")
    response.body
  end

  def send_email(to)
    http = Net::HTTP.new(host_name)
    key_path = "/service/#{@namespace}/#{service_instance.name}"
    debug("POST to #{host_name} #{key_path}")
    response = http.post(key_path, "to=#{CGI.escape(to)}")
    debug("Response: #{response}")
    debug("  Body: #{response.body}")
    response
  end

  def when_running(&block)
    Timeout::timeout(WAITING_TIMEOUT) do
      loop do
        print "---- Waiting for app: "
        begin
          if app.running?
            puts app.health
            break
          else
            puts app.health
          end
        rescue CFoundry::NotStaged
          puts "CFoundry::NotStaged"
        end
        sleep 2
      end
    end
    block.call if block_given?
  end

  private

  def key_path(key)
    "/service/#{@namespace}/#{service_instance.name}/#{key}"
  end

  def debug(msg)
    puts "---- #{msg}"
  end
end
