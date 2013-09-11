class TestEnv
  def self.default
    @default ||= new(ENV.to_hash)
  end

  def initialize(hash)
    @hash = hash
  end

  def apps_domain
    @hash["NYET_APPS_DOMAIN"]
  end
end
