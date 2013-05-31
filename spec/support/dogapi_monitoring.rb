begin
  require "dogapi"
rescue LoadError
  # datadog monitoring is optional
end

require "support/monitoring"

class DogapiMonitoring < Monitoring
  def self.from_env
    return unless defined?(::Dogapi)

    if ENV["NYET_DATADOG_API_KEY"] && ENV["NYET_DATADOG_APP_KEY"]
      new(*ENV.values_at("NYET_DATADOG_API_KEY", "NYET_DATADOG_APP_KEY", "DEPLOYMENT_NAME"))
    end
  end

  def initialize(api_key, app_key, deployment_name)
    @api_key = api_key
    @app_key = app_key
    @deployment_name = deployment_name
  end

  def record_action(action, &blk)
    super.tap do |execution_time|
      record("#{action}.response_time_ms", execution_time)
    end
  end

  private

  def record(name, value)
    full_name = "#{@deployment_name}.nyet.#{name}"
    puts "--- Dogapi record '#{full_name}' with #{value}"

    client.emit_point(full_name, value, {
      role: "core",
      deployment: "cf-#{@deployment_name}",
    })
  end

  def client
    @client ||= Dogapi::Client.new(@api_key, @app_key)
  end
end
