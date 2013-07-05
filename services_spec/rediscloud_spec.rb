require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing RedisCloud', :appdirect => true do
  let(:namespace) { "redis" }
  let(:plan_name) { "20mb" }
  let(:service_name) { "rediscloud-dev" }

  pending "Rediscloud disabled our automatic testing and returns no credentials"
  #it_should_behave_like "A bindable service", "rediscloud"
end
