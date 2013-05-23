require "dogapi"

module DataDogHelper
  DOG_TAGS = {
    role: "core",
    deployment: "cf-#{ENV["DEPLOYMENT_NAME"]}"
  }.freeze

  def with_timer(action)
    start_time = Time.now.to_f
    yield
    test_execution_time = (Time.now.to_f - start_time) * 1000
    if DataDogHelper.datadog
      DataDogHelper.datadog.emit_point("#{ENV["DEPLOYMENT_NAME"]}.nyet.#{action}.response_time_ms", test_execution_time, DOG_TAGS)
    else
      warn "Test '#{action}' took #{test_execution_time} milliseconds."
    end
  end

  def self.emit_pass_fail(passed)
    if self.datadog
      self.datadog.emit_point("#{ENV["DEPLOYMENT_NAME"]}.nyet.status", passed ? 1 : 0, DOG_TAGS)
    else
      warn "DataDog Environment variables missing; not reporting time/status to DataDog."
    end
  end

  private

  def self.datadog
    @datadog ||= begin
      if ENV["DATADOG_API_KEY"] && ENV["DATADOG_APP_KEY"]
        Dogapi::Client.new(ENV["DATADOG_API_KEY"], ENV["DATADOG_APP_KEY"]).freeze
      end
    end
  end
end

RSpec.configure do |config|
  config.include DataDogHelper
end