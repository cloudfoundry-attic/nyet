require 'timeout'
require 'cgi'

class TestApp
  attr_reader :host_name, :service_instance, :app, :example, :signature, :namespace
  STAGING_TIMEOUT = 300

  def initialize(opts)
    @app = opts.fetch(:app)
    @host_name = opts.fetch(:host_name)
    @service_instance = opts.fetch(:service_instance)
    @namespace = opts.fetch(:namespace, nil)
    @example = opts.fetch(:example)
    @signature = opts.fetch(:signature)
  end

  def get_env
    http = Net::HTTP.new(host_name)
    path = "/env"
    make_request_with_retry do
      debug("GET from #{host_name} #{path}")
      http.get(path)
    end.body
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

  def insert_data(megabytes)
    http = Net::HTTP.new(host_name)
    path = "/service/mysql/#{service_instance.name}/write-bulk-data"
    make_request_with_retry do
      debug("POST from #{host_name} #{path} with value #{megabytes}")
      http.post(path, megabytes.to_s)
    end
  end
  alias_method :exceed_quota_by_inserting, :insert_data

  def delete_data(megabytes)
    http = Net::HTTP.new(host_name)
    path = "/service/mysql/#{service_instance.name}/delete-bulk-data"
    make_request_with_retry do
      debug("POST from #{host_name} #{path} with value #{megabytes}")
      http.post(path, megabytes.to_s)
    end
  end
  alias_method :fall_below_quota_by_deleting, :delete_data

  def send_email(to)
    http = Net::HTTP.new(host_name)
    key_path = "/service/#{namespace}/#{service_instance.name}"
    make_request_with_retry do
      debug("POST to #{host_name} #{key_path}")
      http.post(key_path, "to=#{CGI.escape(to)}")
    end
  end

  def make_request_with_retry
    timeout_in_minutes = 10
    timeout = Time.now + timeout_in_minutes * 60
    loop do
      response = yield
      debug 'Services-Nyet-App: ' + response['Services-Nyet-App'].inspect
      debug("Response: #{response.inspect}")
      debug("  Body: #{response.body}")
      if response['Services-Nyet-App'] == 'true'
        raise "Attack of the zombie with signature #{ response['App-Signature']}!!! Expected signature: #{signature}!!! Run for your lives!!!" if response['App-Signature'] != signature

        case response
        when Net::HTTPServiceUnavailable
          debug("Service unavailable. Retrying in #{response['Retry-After']} seconds.")
          if Time.now < timeout
            sleep(response['Retry-After'].to_i)
          else
            raise "Failed to use service within #{timeout_in_minutes} minutes."
          end
        else
          return response
        end
      else
        if Time.now < timeout
          sleep(1)
        else
          example.pending "Failed to reach app within #{timeout_in_minutes} minutes."
        end
      end
    end
  end

  def wait_until_running
    Timeout::timeout(STAGING_TIMEOUT) do
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
    "/service/#{namespace}/#{service_instance.name}/#{key}"
  end

  def debug(msg)
    puts "---- #{msg}"
  end
end
