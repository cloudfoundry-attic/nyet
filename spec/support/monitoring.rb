class Monitoring
  def record_action(action, tags={}, &blk)
    puts "--- Started monitoring #{action} of application."
    t1 = Time.now.to_f
    blk.call

  # Interesting: ensure with a return swallows an error!
  rescue
    raise
  else
    total_time_secs = (Time.now.to_f - t1)
    puts "--- Finished monitoring #{action} of application. " +
             "Took #{total_time_secs.round(2)} seconds."
    total_time_secs * 1000
  end

  def record_metric(name, value, tags={})
    puts "--- Metric #{name} = #{value}  (#{tags.inspect})"
  end
end
