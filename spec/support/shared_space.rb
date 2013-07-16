class SharedSpace
  def self.instance(&block)
    puts "setting shared space #{@space}"
    @space ||= block.call
  end

  def self.cleanup
    puts "deleting share space #{@space}"
    @space.delete!(:recursive => true) if @space
  rescue CFoundry::SpaceNotFound => e
    # space might have been deleted recursively
    # when deleting organization
    # in one of the after blocks
  end
end
