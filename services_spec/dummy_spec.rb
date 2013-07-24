  require "spec_helper"

describe "Managing Dummy", :service => true, :appdirect => true do
  let(:app_name) { "dummy" }
  let(:plan_name) { "small" }
  let(:service_name) { "dummy-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the dummy service" do
    create_and_use_service do |client|
      env = JSON.parse(client.get_env)
      env["#{service_name}-n/a"].first['credentials']['dummy'].should == 'value'
    end
  end
end
