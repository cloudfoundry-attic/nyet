class SharedSpace
  def self.instance(&block)
    @space ||= block.call
  end

  def self.cleanup
    @space.delete!(:recursive => true) if @space
  end
end
