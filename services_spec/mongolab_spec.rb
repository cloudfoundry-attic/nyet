require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing MongoLab' do
  let(:namespace) { "mongodb" }
  let(:plan_name) { "sandbox" }
  let(:service_name) { "mongolab-dev" }
  it_should_behave_like "A bindable service", "mongolab"
end
