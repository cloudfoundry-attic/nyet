require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing RedisCloud' do
  let(:namespace) { "redis" }
  let(:plan_name) { "20mb" }
  let(:service_name) { "rediscloud-dev" }
  it_should_behave_like "A bindable service", "rediscloud"
end
