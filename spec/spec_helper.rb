require "support/cloudwatch"

RSpec.configure do |config|
  passed = true

  config.after(:each) do
    passed = false if example.exception
  end

  config.after(:suite) do
    cloudwatch = CloudWatch.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"], ENV["DEPLOYMENT_NAME"])
    cloudwatch.send_data({ key: "a1 nyet", value: (passed ? 1 : 0) })
  end
end