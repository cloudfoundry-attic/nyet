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
      new(*ENV.values_at("NYET_DATADOG_API_KEY", "NYET_DATADOG_APP_KEY", "DEPLOYMENT_NAME", "NYET_APP"))
    end
  end

  def initialize(api_key, app_key, deployment_name, app_type)
    @api_key = api_key
    @app_key = app_key
    @deployment_name = deployment_name
    @app_type = app_type
  end

  def record_action(action, tags = {}, &blk)
    super.tap do |execution_time|
      record("#{action}.response_time_ms", execution_time, tags)
    end
  end

  def record_metric(name, value, tags = {})
    record(name, value, tags)
  end

  private

  def record(name, value, tags = {})
    full_name = "nyet.#{name}"
    deployment = @deployment_name
    deployment = "cf-#{deployment}" unless deployment.start_with?("cf-")
    tags = {
        role: "core",
        deployment: deployment,
        app_type: @app_type,
    }.merge(tags).collect{|k,v| "#{k}:#{v}" }
    puts "--- Dogapi record '#{full_name}' with #{value}  #{tags.inspect}"
    client.emit_point(full_name, value, :tags => tags)
  end

  def client
    @client ||= Dogapi::Client.new(@api_key, @app_key)
  end
end
