require "spec_helper"
require "support/dogapi_monitoring"

describe DogapiMonitoring do
  describe "#record_action" do
    context "given a deployment without a 'cf-' prefix" do
      it "prepends 'cf-' to the deployment name" do
        client = double('client')
        client.
            should_receive(:emit_point).
            with(instance_of(String),
                 instance_of(Float),
                 tags: %w(role:core deployment:cf-deployment_name app_type:app_type))

        dogapi = DogapiMonitoring.new('api_key', 'app_key', 'deployment_name', 'app_type', client)

        dogapi.record_action(:action) { }
      end
    end

    context "given a deployment with a 'cf-' prefix" do
      it "does not prepend 'cf-' to the deployment name" do
        client = double('client')
        client.
            should_receive(:emit_point).
            with(instance_of(String),
                 instance_of(Float),
                 tags: %w(role:core deployment:cf-deployment_name app_type:app_type))

        dogapi = DogapiMonitoring.new('api_key', 'app_key', 'cf-deployment_name', 'app_type', client)

        dogapi.record_action(:action) { }
      end
    end
  end
end
