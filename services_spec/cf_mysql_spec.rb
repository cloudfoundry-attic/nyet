require "spec_helper"
require "active_support/core_ext/numeric"
require "timeout"

describe "Enforcing MySQL quota", :service => true do
  let (:timeout) { 120 }

  let(:app_name) { "mysql-quota-check" }
  let(:namespace) { "mysql" }
  let(:plan_name) { "free" }
  let(:service_name) { "cf-mysql" }

  def verify_read_succeeds(expected_value)
    expect(@client.get_value('key')).to eq(expected_value)
  end

  def verify_insert_fails
    timer_start = Time.now
    Timeout::timeout(timeout) do
      puts "attempting to insert into the database"
      loop do
        response = @client.insert_value('after_enforcement', 'this should not be allowed in DB')
        if (response.is_a?(Net::HTTPInternalServerError) &&
            response.body =~ /Error: (INSERT|UPDATE) command denied .* for table 'data_values'/)
          break
        end
        sleep 0.5
      end
    end
    puts "Database insert disallowed as expected. Took #{Time.now - timer_start} seconds"
  end

  def verify_insert_succeeds(insert_value)
    timer_start = Time.now
    Timeout::timeout(timeout) do
      puts "attempting to insert into the database"
      loop do
        @client.insert_value('key', insert_value)
        result = @client.get_value('key')
        break if result == insert_value
        sleep 1
      end
    end
    puts "Database insert succeeded. Took #{Time.now - timer_start} seconds"
  end

  def exceed_quota_by_inserting(bytes)
    response = @client.insert_data(bytes)
    expect(response).to be_a Net::HTTPSuccess
  end

  def fall_below_quota_by_deleting(bytes)
    response = @client.delete_data(bytes)
    expect(response).to be_a Net::HTTPSuccess
  end

  it "enforces the storage quota" do
    create_and_use_managed_service do |client|
      @client = client

      verify_insert_succeeds('first_value')

      exceed_quota_by_inserting(11.megabytes)

      verify_insert_fails
      verify_read_succeeds('first_value')

      fall_below_quota_by_deleting(3.megabytes)

      verify_insert_succeeds('second_value')
      verify_read_succeeds('second_value')
    end
  end
end



