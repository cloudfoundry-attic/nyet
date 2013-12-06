require "spec_helper"

describe "Managing RedisCloud", :service => true, :appdirect => true do
  let(:app_name) { "rediscloud" }
  let(:namespace) { "redis" }
  let(:plan_name) { "25mb" }
  let(:service_name) { "rediscloud-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the RedisCloud service" do
    pending("app direct fixing their issues with redis cloud") do
      create_and_use_managed_service do |client|
        client.insert_value('key', 'value').should be_a Net::HTTPSuccess
        client.get_value('key').should == 'value'
      end
    end

  end
end
