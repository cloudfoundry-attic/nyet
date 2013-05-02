require "support/cloudwatch"

CloudWatch.configure(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"], ENV["DEPLOYMENT_NAME"])

module CloudwatchHelper
  def with_timer(action)
    start_time = Time.now.to_f
    yield
    test_execution_time = (Time.now.to_f - start_time) * 1000
    CloudWatch.add({ key: "a1.nyet.#{action}.response_time_ms", value: test_execution_time })
  end
end

RSpec.configure do |config|
  config.include CloudwatchHelper
  passed = true

  config.after(:each) do
    passed = false if example.exception
  end

  config.after(:suite) do
    CloudWatch.add({ key: "a1.nyet.status", value: (passed ? 1 : 0) })
    CloudWatch.send_all
  end
end