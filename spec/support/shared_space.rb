class SharedSpace
  def self.instance(&block)
    @space ||= block.call
  end

  def self.cleanup
    @space.delete!(:recursive => true) if @space
  end
end

RSpec.configure do |config|
  config.after(:suite) { SharedSpace.cleanup }
end
