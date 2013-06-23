require 'spec_helper'
require 'net/http'
require 'support/test_app'

describe 'Managing ClearDB' do
  let(:namespace) { "mysql" }
  let(:plan_name) { "spark" }
  let(:service_name) { "cleardb-dev" }
  it_should_behave_like "A bindable service", "cleardb"
end