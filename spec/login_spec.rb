require 'spec_helper'

require 'cfoundry'

describe 'logging in' do
  let(:username) { ENV['NY_USERNAME'] }
  let(:password) { ENV['NY_PASSWORD'] }
  let(:target) { ENV['NY_TARGET'] }

  it 'can log in successfully' do
    client = CFoundry::V2::Client.new(target)
    client.login(username, password)
    client.should be_logged_in
  end
end
