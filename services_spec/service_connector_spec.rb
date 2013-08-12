require "spec_helper"
require "fileutils"
require "httparty"

describe "Service Connector", cf: true do
  let(:service_name) { "user-provided" }
  let(:service_instance_name) { "user-provided-service-instance" }
  let(:app_name) { "services-management-nyet-app" }
  let(:app_signature) { SecureRandom.uuid }

  it "allows the user to push an app with a newly created user provided service instance and bind it" do
    app_url = ""
    Dir.chdir(test_app_path) do
      BlueShell::Runner.run("#{cf_bin} push --no-manifest --no-start") do |runner|
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
        runner.send_keys "#{service_name}"

        runner.should say "Name?>"
        runner.send_keys service_instance_name

        runner.should say "What credential parameters should applications use to connect to this service instance?\n(e.g. hostname, port, password)>"
        runner.send_keys "user, password"

        runner.should say "user>"
        runner.send_keys "LeBron"

        runner.should say "password>"
        runner.send_keys "Miami"

        runner.should say /Creating service #{service_instance_name}.*OK/
        runner.should say /Binding .+ to .+ OK/

        runner.should say "Create another service?>"
        runner.send_keys "n"

        runner.should say "Bind other services to application?>"
        runner.send_keys "n"

        runner.should say "Uploading #{app_name}... OK", 180
      end

      BlueShell::Runner.run("#{cf_bin} set-env #{app_name} APP_SIGNATURE #{app_signature}") do |runner|
        runner.should say "Updating #{app_name}"
      end

      BlueShell::Runner.run("#{cf_bin} start #{app_name}") do |runner|
        runner.should say "Preparing to start #{app_name}... OK", 180
        runner.should say "Checking status of app '#{app_name}'", 180
        runner.should say "1 of 1 instances running"
        runner.should say /Push successful! App '#{app_name}' available at.*\n/
        app_url = runner.output.scan(/http:\/\/#{app_name}.*/).last
      end

      result = get_env(app_url)
      env = JSON.parse(result)
      env.should include(
        "user-provided" => [
          {
            "credentials" => {"user" => "LeBron", "password" => "Miami"},
            "name" => service_instance_name,
            "tags" => [],
            "label" => "user-provided",
          }
        ]
      )

    end
  end

  def get_env(app_url)
    puts "---- GET from #{app_url}/env"
    HTTParty.get("#{app_url}/env").body
  end
end
