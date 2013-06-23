require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing CloudAMQP' do
  let(:namespace) { "amqp" }
  let(:plan_name) { "lemur" }
  let(:service_name) { "cloudamqp-dev" }
  it_should_behave_like "A bindable service", "cloudamqp"
end
