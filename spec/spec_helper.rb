require "bundler/setup"
require "support/monitoring"
require "support/dogapi_monitoring"
require "support/admin_user"
require "support/regular_user"

module MonitoringHelpers
  def monitoring
    @monitoring ||= (DogapiMonitoring.from_env || Monitoring.new)
  end
end

RSpec.configure do |config|
  config.include(MonitoringHelpers)
end
