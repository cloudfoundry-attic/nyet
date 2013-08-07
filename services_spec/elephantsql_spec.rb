require "spec_helper"

describe "Managing ElephantSQL", :service => true, :appdirect => true do
  let(:app_name) { "elephantsql" }
  let(:namespace) { "pg" }
  let(:plan_name) { "turtle" }
  let(:service_name) { "elephantsql-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the ElephantSQL service" do
    create_and_use_managed_service do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end
