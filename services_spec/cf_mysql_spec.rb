require 'spec_helper'
require 'active_support/core_ext/numeric'
require 'timeout'

describe 'Enforcing MySQL quota', :service => true do
  let(:app_name) { 'mysql-quota-check' }
  let(:namespace) { 'mysql' }
  let(:plan_name) { '100mb' }
  let(:service_name) { 'p-mysql' }
  let(:quota_enforcer_sleep_time) { 2 }

  it 'enforces the storage quota' do
    create_and_use_managed_service do |client|
      puts '*** Proving we can write'
      expect(client).to be_able_to_write('key', 'first_value')
      puts '*** Proving we can read'
      expect(client).to be_able_to_read('key', 'first_value')

      puts '*** Exceeding quota'
      client.exceed_quota_by_inserting(ENV.fetch('MYSQL_V2_MAX_MB').to_i)

      puts '*** Sleeping to let quota enforcer run'
      sleep quota_enforcer_sleep_time

      puts '*** Proving we cannot write'
      expect(client).to fail_to_insert('after_enforcement', 'this should not be allowed in DB')
      puts '*** Proving we can read'
      expect(client).to be_able_to_read('key', 'first_value')

      puts '*** Deleting below quota'
      client.fall_below_quota_by_deleting(20)

      puts '*** Sleeping to let quota enforcer run'
      sleep quota_enforcer_sleep_time

      puts '*** Proving we can write'
      expect(client).to be_able_to_write('key', 'second_value')
      puts '*** Proving we can read'
      expect(client).to be_able_to_read('key', 'second_value')
    end
  end

  RSpec::Matchers.define :be_able_to_write do |key, value|
    match do |client|
      puts '---- Attempting to insert into the database'
      client.insert_value(key, value)
      client.get_value(key) == value
    end

    failure_message_for_should do |_|
      'expected that client should be able to write to the database'
    end
  end

  RSpec::Matchers.define :fail_to_insert do |key, value|
    match do |client|
      puts '---- Attempting to insert into the database'
      response = client.insert_value(key, value)
      /Error: (INSERT|UPDATE) command denied .* for table 'data_values'/ === response.body
    end

    failure_message_for_should do |_|
      'expected that client should NOT be able to write to the database'
    end
  end

  RSpec::Matchers.define :be_able_to_read do |key, value|
    match do |client|
      puts '---- Attempting to read from the database'
      client.get_value(key) == value
    end

    failure_message_for_should do |_|
      'expected that client should be able to read from the database'
    end
  end
end

describe 'Using a new service instance', :service => true do
  let(:app_name) { 'mysql-v2' }
  let(:namespace) { 'mysql' }
  let(:plan_name) { '100mb' }
  let(:service_name) { 'p-mysql' }

  it 'allows users to create, bind, read, write, unbind, and delete the Mysql service' do
    create_and_use_managed_service do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end

describe 'Using a long-running service instance', :service => true do

  let(:app_name) { 'use-existing-mysql' }
  let(:namespace) { 'mysql' }
  let(:plan_name) { 'free' }
  let(:service_name) { 'p-mysql' }

  it 'allows us to bind and unbind to an existing instance' do
    use_managed_service_instance(ENV.fetch('NYET_EXISTING_MYSQL_V2_INSTANCE_ID')) do |client|
      client.insert_value('key', 'value').should be_a Net::HTTPSuccess
      client.get_value('key').should == 'value'
    end
  end
end
