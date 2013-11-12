require "spec_helper"

describe "Managing CloudAMQP", service: true, appdirect: true, isv: true do
  let(:app_name) { "cloudamqp" }
  let(:namespace) { "amqp" }
  let(:plan_name) { "lemur" }
  let(:service_name) { "cloudamqp-dev" }

  it "allows users to create, bind, read, write, unbind, and delete the CloudAMQP service" do
    create_and_use_managed_service do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end
