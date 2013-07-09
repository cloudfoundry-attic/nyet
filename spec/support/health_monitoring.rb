module HealthMonitoringHelpers
  def with_health_monitoring(name)
    after do
      next if example.pending?
      health = example.exception ? 0 : 1
      monitoring.record_metric(name, health)
    end
  end
end

RSpec.configure do |config|
  config.extend(HealthMonitoringHelpers)
end
