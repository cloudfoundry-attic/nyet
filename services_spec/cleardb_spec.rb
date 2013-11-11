require "spec_helper"

describe "Managing ClearDB", service: true, appdirect: true, isv: true do
  let(:app_name) { "cleardb" }
  let(:namespace) { "mysql" }
  let(:plan_name) { "spark" }
  let(:service_name) { "cleardb-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the ClearDB service" do
    create_and_use_managed_service do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end
