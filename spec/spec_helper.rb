require "bundler/setup"

require "support/monitoring"
require "support/dogapi_monitoring"
require "support/tagged_monitoring"
require "support/health_monitoring"

require "support/admin_user"
require "support/regular_user"
require "support/shared_space"
require "support/user_with_org"
require "support/service_shared_examples"

module MonitoringHelpers
  def monitoring
    @monitoring ||= (DogapiMonitoring.from_env || Monitoring.new)
  end
end

RSpec.configure do |config|
  config.include(MonitoringHelpers)
end
