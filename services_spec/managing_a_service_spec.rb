require "spec_helper"
require "fileutils"

DATADOG_SUCCESS = 1
DATADOG_FAILURE = 0
DATADOG_CF_DOWN = 0.6
class CantUploadToCf < StandardError; end


describe "Managing a Service", :appdirect => true, :cf => true do
  let(:plan_name) { "small" }
  let(:service_provider_prefix) { ENV["NYET_SERVICE_PROVIDER_PREFIX"] || '' }
  let(:service_name) { "#{service_provider_prefix}dummy-dev" }
  let(:service_instance_name) { "service-management-tester" }
  let(:app_name) { "services-management-nyet-app" }
  let(:dog_tags) { {service: 'service-management' } }

  it "allows the user to push an app with a newly created service and bind it" do
    begin
      prep_workspace_for_cf_push

      Dir.chdir(test_app_path) do
        BlueShell::Runner.run("#{cf_bin} push --no-manifest --no-start --trace 2>>#{tmp_dir}/cf_trace.log") do |runner|
          runner.should say "Name>"
          runner.send_keys app_name

          runner.should say "Instances>"
          runner.send_keys "1"

          runner.should say "Memory Limit>"
          runner.send_keys "128M"

          runner.should say "Subdomain> #{app_name}"
          runner.send_keys app_name

          runner.should say "Domain>"
          runner.send_return

          runner.should say "Create services for application?>"
          runner.send_keys "y"

          runner.should say "What kind?>"
          runner.send_keys "#{service_name} n/a"

          runner.should say "Name?>"
          runner.send_keys service_instance_name

          runner.should say "Which plan?>"
          runner.send_keys plan_name

          runner.should say /Creating service #{service_instance_name}.*OK/
          runner.should say /Binding .+ to .+ OK/

          runner.should say "Create another service?>"
          runner.send_keys "n"

          runner.should say "Bind other services to application?>"
          runner.send_keys "n"

          begin
            runner.with_timeout 180 do
              runner.should say "Uploading #{app_name}... OK"
            end
          rescue SignalException, RSpec::Expectations::ExpectationNotMetError
            raise CantUploadToCf
          end
        end

        set_app_signature_env_variable(app_name)
        start_app(app_name)
        env = get_env(app_name, space, service_instance_name)
        env["#{service_name}-n/a"].first['credentials']['dummy'].should == 'value'
      end

      monitoring.record_metric("services.health", DATADOG_SUCCESS, dog_tags)
    rescue CantUploadToCf, CfHelpers::CantStartApp, CfHelpers::CantConnectToCf
      monitoring.record_metric("services.health", DATADOG_CF_DOWN, dog_tags)
    rescue Exception => e
      monitoring.record_metric("services.health", DATADOG_FAILURE, dog_tags)
      raise e
    end
  end
end
