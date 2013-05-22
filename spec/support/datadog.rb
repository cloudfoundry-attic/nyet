require "dogapi"

module DataDogHelper
  DOG_TAGS = {role: 'core', }.freeze

  def with_timer(action)
    start_time = Time.now.to_f
    yield
    test_execution_time = (Time.now.to_f - start_time) * 1000
    if datadog
      datadog.emit_point("#{deployment_name}.nyet.#{action}.response_time_ms", test_execution_time, DOG_TAGS)
    else
      warn "Test #{action} took #{test_execution_time}."
    end
  end

  def emit_pass_fail(passed)
    if datadog
      datadog.emit_point("#{deployment_name}.nyet.status", passed ? 1 : 0, DOG_TAGS)
    else
      warn "DataDog Environment variables missing; not reporting time/status to DataDog."
    end
  end

  private

  def deployment_name
    ENV["DEPLOYMENT_NAME"]
  end

  def datadog
    @datadog ||= begin
      if ENV["DATADOG_API_KEY"] && ENV["DATADOG_APP_KEY"]
        Dogapi::Client.new(ENV["DATADOG_API_KEY"], ENV["DATADOG_APP_KEY"]).freeze
      end
    end
  end
end

RSpec.configure do |config|
  config.include DataDogHelper
  passed = true

  config.after(:each) do
    passed = false if example.exception
  end

  config.after(:suite) do
    emit_pass_fail(passed)
  end
end