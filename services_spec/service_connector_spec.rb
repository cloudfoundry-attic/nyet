require 'spec_helper'

describe "service connector", service: true do
  let(:app_name) { "upapp" }
  it "creates, binds, unbinds, and deletes a service" do
    credentials = { "foo" => "bar" }
    create_and_use_service_connector(credentials) do |test_app|
      env = JSON.parse(test_app.get_env)
      env.should include(
        "user-provided" => [
          {
            "credentials" => credentials,
            "name" => instance_name,
            "tags" => [],
            "label" => "user-provided",
          }
        ]
      )
    end
  end
end
