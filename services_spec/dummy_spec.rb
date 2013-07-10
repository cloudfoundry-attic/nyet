require "spec_helper"
require "fileutils"

describe "Managing Dummy", :only_in_staging => true, :appdirect => true do
  let(:namespace) { "dummy-dev" }
  let(:plan_name) { "small" }
  let(:service_name) { "dummy-dev" }
  let(:service_instance_name) { 'dummy-tester' }
  let(:app_name) { 'dummy' }

  let(:dog_tags) { {service: 'dummy'} }
  let(:test_app_path) { File.expand_path("../apps/ruby/app_sinatra_service", File.dirname(__FILE__)) }
  let(:fake_home)     { File.expand_path("../tmp/fake_home", File.dirname(__FILE__)) }
  let(:cf_bin) { `which cf`.chomp }

  with_user_with_org
  with_shared_space

  before do
    FileUtils.mkdir_p fake_home
    @original_home = ENV['HOME']
    ENV['HOME'] = fake_home
    login
  end

  after do
    ENV['HOME'] = @original_home
  end

  def login
    set_target
    logout

    username = ENV['NYET_REGULAR_USERNAME']
    password = ENV['NYET_REGULAR_PASSWORD']

    cmd = "#{cf_bin} login #{username} --password #{password} -o #{org.name} -s #{space.name}"
    BlueShell::Runner.run(cmd) do |runner|
      runner.wait_for_exit 60
    end
  end

  def logout
    BlueShell::Runner.run("#{cf_bin} logout") do |runner|
      runner.wait_for_exit 60
    end
  end

  def set_target
    target = ENV['NYET_TARGET']
    BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
      runner.wait_for_exit(20)
    end
  end


  it "allows users to create, bind, unbind, and delete the dummy service" do
    Dir.chdir(test_app_path) do
      BlueShell::Runner.run("#{cf_bin} push --no-manifest") do |runner|
        runner.should say "Name>", 10
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
        runner.should say "Starting #{app_name}... OK", 180
        runner.should say "Checking #{app_name}...", 180
        runner.should say "1/1 instances"
        runner.should say "OK", 30
      end

      space.app_by_name(app_name).delete(recursive: true)
      space.service_instance_by_name(service_instance_name).delete(recursive: true)
    end
  end
end
