require "spec_helper"
require "active_support/core_ext/numeric"


describe "Enforcing MySQL quota", :service => true do
  let(:app_name) { "mysql-quota-check" }
  let(:namespace) { "mysql" }
  let(:plan_name) { "free" }
  let(:service_name) { "cf-mysql" }

  def verify_read_succeeds
    expect(@client.get_value('key')).to eq 'value'
  end

  def verify_insert_fails
    response = @client.insert_value('after_enforcement', 'this should not be allowed in DB')
    expect(response).to be_a Net::HTTPInternalServerError
    expect(response.body).to match /Error: INSERT command denied .* for table 'data_values'/
  end

  def verify_insert_succeeds
    @client.insert_value('key', 'value')
    expect(@client.get_value('key')).to eq 'value'
  end

  def exceed_quota_by_inserting(bytes)
    response = @client.insert_data(bytes)
    expect(response).to be_a Net::HTTPSuccess

    # current enforcement mechanism runs every 60 seconds
    puts "Sleeping.  Waiting for enforcement...."
    sleep 70
  end

  def fall_below_quota_by_deleting(bytes)
    response = @client.delete_data(bytes)
    expect(response).to be_a Net::HTTPSuccess

    expect(@client.get_value('key')).to eq 'value'

    puts "Sleeping.  Awaiting freedom..."
    sleep 70
  end

  it "enforces the storage quota" do
    create_and_use_managed_service do |client|
      @client = client

      verify_insert_succeeds

      exceed_quota_by_inserting(11.megabytes)
      verify_insert_fails
      verify_read_succeeds

      fall_below_quota_by_deleting(2.megabytes)
      verify_insert_succeeds
    end
  end
end



