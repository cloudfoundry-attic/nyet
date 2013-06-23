require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing ElephantSQL' do
  let(:namespace) { "pg" }
  let(:plan_name) { "turtle" }
  let(:service_name) { "elephantsql-dev" }
  it_should_behave_like "A bindable service", "elephantsql"
end