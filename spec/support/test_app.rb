require 'timeout'
require 'cgi'

class TestApp
  attr_reader :host_name, :service_instance, :app, :example
  # temporarily bumping this to 10mins
  # sunset this after the HM fix
  WAITING_TIMEOUT = 600

  def initialize(app, host_name, service_instance, namespace, example)
    @app = app
    @host_name = host_name
    @service_instance = service_instance
    @namespace = namespace
    @example = example
  end

  def insert_value(key, value)
    http = Net::HTTP.new(host_name)
    key_path = key_path(key)
    make_request_with_retry do
      debug("POST to #{host_name} #{key_path}")
      http.post(key_path, value)
    end
  end

  def get_value(key)
    http = Net::HTTP.new(host_name)
    key_path = key_path(key)
    make_request_with_retry do
      debug("GET from #{host_name} #{key_path}")
      http.get(key_path)
    end.body
  end

  def send_email(to)
    http = Net::HTTP.new(host_name)
    key_path = "/service/#{@namespace}/#{service_instance.name}"
    make_request_with_retry do
      debug("POST to #{host_name} #{key_path}")
      http.post(key_path, "to=#{CGI.escape(to)}")
    end
  end

  def make_request_with_retry
    Timeout::timeout(WAITING_TIMEOUT) do
      while true
        response = yield
        debug 'header' + response['Services-Nyet-App'].inspect
        if response['Services-Nyet-App'] == 'true'
          debug("Response: #{response}")
          debug("  Body: #{response.body}")
          return response
        end
        sleep(1)
      end
    end
  rescue TimeoutError
    example.pending "Router malfunction"
  end

  def wait_until_running
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
  end

  private

  def key_path(key)
    "/service/#{@namespace}/#{service_instance.name}/#{key}"
  end

  def debug(msg)
    puts "---- #{msg}"
  end
end
