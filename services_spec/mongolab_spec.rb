require "spec_helper"

describe "Managing Mongolab", service: true, appdirect: true, isv: true do
  let(:app_name) { "mongolab" }
  let(:namespace) { "mongodb" }
  let(:plan_name) { "sandbox" }
  let(:service_name) { "mongolab-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the Mongolab service" do
    create_and_use_managed_service do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end
