class TaggedMonitoring
  def initialize(monitoring, tags)
    @monitoring = monitoring
    @tags = tags
  end

  def record_action(action, tags={}, &blk)
    @monitoring.record_action(action, @tags.merge(tags), &blk)
  end

  def record_metric(name, value, tags={})
    @monitoring.record_metric(name, value, @tags.merge(tags))
  end
end

module TaggedMonitoringHelpers
  def with_tagged_monitoring(tags)
    # Interesting: you can call super from define_method
    # if params are passed in explicitly.
    define_method(:monitoring) do
      TaggedMonitoring.new(super(), tags.clone)
    end
  end
end

RSpec.configure do |config|
  config.extend(TaggedMonitoringHelpers)
end
