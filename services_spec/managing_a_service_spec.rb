require "spec_helper"
require "fileutils"

DATADOG_SUCCESS = 1
DATADOG_FAILURE = 0
DATADOG_CF_DOWN = 0.6

describe "Managing a Service", :appdirect => true, :cf => true do
  let(:plan_name) { "small" }
  let(:service_provider_prefix) { ENV["NYET_SERVICE_PROVIDER_PREFIX"] || '' }
  let(:service_name) { "#{service_provider_prefix}dummy-dev" }
  let(:service_instance_name) { "nyet-smoke-test-service-instance3" }
  let(:persistent_app_name) { "services-nyets-app" }
  let(:dog_tags) { { service: 'service-management' } }

  before do
    prep_workspace_for_cf_push
    BlueShell::Runner.run("#{cf_bin} stop #{persistent_app_name} --trace 2>>#{tmp_dir}/cf_trace.log") {}
  end

  after do
    BlueShell::Runner.run("#{cf_bin} stop #{persistent_app_name} --trace 2>>#{tmp_dir}/cf_trace.log") do |runner|
      runner.should say "OK"
    end
  end

  it "allows the user to push an app with a newly created service and bind it" do
    begin
      Dir.chdir(test_app_path) do
        BlueShell::Runner.run("#{cf_bin} create-service #{service_name} #{service_instance_name}  --plan #{plan_name} --trace 2>>#{tmp_dir}/cf_trace.log") do |runner|
          runner.should say "OK"
        end

        BlueShell::Runner.run("#{cf_bin} bind-service #{service_instance_name} #{persistent_app_name} --trace 2>>#{tmp_dir}/cf_trace.log") do |runner|
          runner.should say "OK"
        end
        set_app_signature_env_variable(persistent_app_name)
        start_app(persistent_app_name)
        env = get_env(persistent_app_name, space, service_instance_name)

        v2_service = env[service_name]
        v1_service = env["#{service_name}-n/a"]

        if v2_service
          v2_service.first['credentials']['dummy'].should == 'value'
        else
          v1_service.first['credentials']['dummy'].should == 'value'
        end
      end

      monitoring.record_metric("services.health", DATADOG_SUCCESS, dog_tags)
    rescue CfHelpers::CantStartApp, CfHelpers::CantConnectToCf => e
      monitoring.record_metric("services.health", DATADOG_CF_DOWN, dog_tags)
    rescue Exception => e
      monitoring.record_metric("services.health", DATADOG_FAILURE, dog_tags)
      raise e
    end
  end
end
