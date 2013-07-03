require "bundler/setup"
require "support/monitoring"
require "support/dogapi_monitoring"
require "support/admin_user"
require "support/regular_user"
require "support/shared_space"
require "support/service_shared_examples"

module MonitoringHelpers
  def monitoring
    @monitoring ||= (DogapiMonitoring.from_env || Monitoring.new)
  end
end

RSpec.configure do |config|
  config.include(MonitoringHelpers)
  config.after :suite, example_group: { file_path: /\/services_spec\// } do
    SharedSpace.cleanup
  end
end
