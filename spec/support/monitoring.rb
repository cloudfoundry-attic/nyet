class Monitoring
  def record_action(action, &blk)
    t1 = Time.now.to_f
    blk.call
    (Time.now.to_f - t1) * 1000
  end
end
