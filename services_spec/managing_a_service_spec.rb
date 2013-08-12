require "spec_helper"
require "fileutils"

describe "Managing a Service", :only_in_staging => true, :appdirect => true, :cf => true do
  let(:plan_name) { "small" }
  let(:service_name) { "dummy-dev" }
  let(:service_instance_name) { "service-management-tester" }
  let(:app_name) { "services-management-nyet-app" }

  it "allows the user to push an app with a newly created service and bind it" do
    Dir.chdir(test_app_path) do
      BlueShell::Runner.run("#{cf_bin} push --no-manifest") do |runner|
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

        runner.should say "Uploading #{app_name}... OK", 180
        runner.should say "Preparing to start #{app_name}... OK", 180
        runner.should say "Checking status of app '#{app_name}'", 180
        runner.should say "1 of 1 instances running"
        runner.should say "Push successful!", 30
      end

      app_signature = SecureRandom.uuid
      BlueShell::Runner.run("#{cf_bin} set-env #{app_name} APP_SIGNATURE #{app_signature} --restart") do |runner|
        runner.should say "Preparing to start #{app_name}... OK", 180
        runner.should say "Checking status of app '#{app_name}'", 180
        runner.should say "1 of 1 instances running"
      end

      app_handle = space.app_by_name(app_name)
      route = app_handle.routes.first
      service_instance = space.service_instance_by_name(service_instance_name)
      namespace = nil

      test_app = TestApp.new(
        app_handle,
        route.name,
        service_instance,
        namespace,
        self,
        app_signature
      )

      env = JSON.parse(test_app.get_env)
      env["#{service_name}-n/a"].first['credentials']['dummy'].should == 'value'
    end
  end
end
