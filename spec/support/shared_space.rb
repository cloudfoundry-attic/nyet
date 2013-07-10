class SharedSpace
  def self.instance(&block)
    @space ||= block.call
  end

  def self.cleanup
    @space.delete!(:recursive => true) if @space
  rescue CFoundry::SpaceNotFound => e
    # space might have been deleted recursively
    # when deleting organization
    # in one of the after blocks
  end
end
