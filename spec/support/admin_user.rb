require "uri"
require "securerandom"
require "cfoundry"

class AdminUser
  def self.from_env
    new(*%w(NYET_TARGET NYET_ADMIN_USERNAME NYET_ADMIN_PASSWORD).map do |var|
      ENV[var] || raise(ArgumentError, "missing #{var}")
    end)
  end

  def initialize(target, username, password)
    @target = URI(target)
    @username = username
    @password = password
  end

  def create_org(regular_user)
    raise ArgumentError, "only one organization can be created" if @org

    raise ArgumentError, "did not find paid quota" \
      unless quota = client.quota_definition_by_name("paid")

    debug(:create, @org = client.organization.tap do |org|
      org.name = "nyet-org-#{SecureRandom.uuid}"
      org.quota_definition = quota
      org.users = [regular_user]
      org.managers = [regular_user]
      org.create!
    end)
  end

  def delete_org
    if @org
      debug(:delete, @org)
      @org.delete!(:recursive => true)
    end
  end

  private

  def debug(action, object)
    puts "--- #{action}: #{object.inspect} (*admin* user: #{client.current_user.inspect})"
    object
  end

  # Do not expose admin cf client to everyone
  # so that we have complete control over what actions
  # are done by the admin account *in this class*!
  def client
    @client ||= CFoundry::Client.new(@target.to_s).tap do |c|
      c.login(@username, @password)
    end
  end
end
