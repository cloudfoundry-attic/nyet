require 'spec_helper'

require 'cfoundry'

describe 'logging in' do
  it 'can log in successfully' do
    logged_in_client.should be_logged_in
  end
end
