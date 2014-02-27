module CfHelpers
  class CantStartApp < StandardError; end
  class CantConnectToCf < StandardError; end

  def self.included(base)
    base.instance_eval do
      let(:test_app_path) { File.expand_path("../../apps/ruby/app_sinatra_service", File.dirname(__FILE__)) }
      let(:tmp_dir) { File.expand_path("../../tmp", File.dirname(__FILE__)) }
      let(:fake_home) { File.join(tmp_dir, 'fake_home') }
      let(:cf_bin)  { File.join(bin_dir, 'cf') }
      let(:bin_dir) { File.join(tmp_dir, 'bin') }
      let(:gem_dir) { File.join(tmp_dir, 'gems') }
      let(:app_signature) { SecureRandom.uuid }

      with_user_with_org
      with_shared_space

      around do |example|
        original_env = ENV.to_hash
        Bundler.with_clean_env do
          example.call
        end
        ENV.replace(original_env)
      end

      after do
        crash_log = File.join(fake_home, '.cf', 'crash')
        if File.exists?(crash_log)
          puts `cat #{crash_log}`
          FileUtils.rm(crash_log)
        end

        clean_up_service_instance(service_instance_name)
      end
    end
  end

  def prep_workspace_for_cf_push
    FileUtils.rm_rf tmp_dir
    FileUtils.mkdir_p fake_home
    FileUtils.mkdir_p bin_dir
    FileUtils.mkdir_p gem_dir

    ENV['HOME'] = fake_home

    use_newest_cf
    login

    clean_up_service_instance(service_instance_name)
  end


  def login
    set_target
    logout

    username = ENV['NYET_REGULAR_USERNAME']
    password = ENV['NYET_REGULAR_PASSWORD']

    cmd = "#{cf_bin} login #{username} --password #{password} -o #{org.name} -s #{space.name}"
    BlueShell::Runner.run(cmd) do |runner|
      runner.with_timeout 60 do
        runner.wait_for_exit
      end
    end
  end

  def logout
    BlueShell::Runner.run("#{cf_bin} logout") do |runner|
      runner.with_timeout 60 do
        runner.wait_for_exit
      end
    end
  end

  def set_target
    target = ENV['NYET_TARGET']

    begin
      BlueShell::Runner.run("#{cf_bin} target #{target}") do |runner|
        runner.with_timeout 20 do
          runner.wait_for_exit
        end
      end

    rescue Timeout::Error
      raise CfHelpers::CantConnectToCf, "trying to target #{target} with #{cf_bin} command."
    end
  end

  def clean_up_service_instance(service_instance_name)
    if service_instance = space.service_instance_by_name(service_instance_name)
      service_instance.delete!(recursive: true)
    end
  rescue => e
    if e.respond_to?(:request_trace)
      puts "<<<"
      puts e.request_trace
    end

    if e.respond_to?(:response_trace)
      puts e.response_trace
      puts ">>>"
      puts ""
    end

    raise
  end

  def clean_up_app(app_name)
    regular_user.clean_up_route_from_previous_run(app_name)
    if app = space.app_by_name(app_name)
      app.delete!(recursive: true)
    end
  end

  def use_newest_cf
    ENV['GEM_HOME'] = gem_dir
    ENV['GEM_PATH'] = gem_dir

    unless system("gem install --install-dir #{gem_dir} --bindir #{bin_dir} --no-ri --no-rdoc cf 2>&1 >/dev/null")
      puts "Retrying install of latest CF with more verbosity"
      system("gem install --install-dir #{gem_dir} --bindir #{bin_dir} --no-ri --no-rdoc cf 2>&1") or
        raise "Couldn't download latest cf on second retry"
    end

    puts "Installed the newest version of cf gem: #{`#{cf_bin} --version`.chomp}"
  end

  def set_app_signature_env_variable(app_name)
    BlueShell::Runner.run("#{cf_bin} set-env #{app_name} APP_SIGNATURE #{app_signature}") do |runner|
      runner.with_timeout 180 do
        runner.should say "Updating env variable APP_SIGNATURE for app #{app_name}... OK"
      end
    end
  end

  def start_app(app_name)
    BlueShell::Runner.run("#{cf_bin} start --trace #{app_name} 2>>#{tmp_dir}/cf_trace.log") do |runner|
      runner.with_timeout 180 do
        runner.should say "Preparing to start #{app_name}... OK"
      end
      runner.with_timeout 180 do
        runner.should say "Checking status of app '#{app_name}'"
      end
      runner.should say "1 of 1 instances running"
      runner.should say "Push successful"
    end
  rescue RSpec::Expectations::ExpectationNotMetError => err
    raise CantStartApp
  end

  def get_env(app_name, space, service_instance_name)
    app_handle = space.app_by_name(app_name)
    test_app = TestApp.new(
      app: app_handle,
      host_name: app_handle.routes.first.name,
      service_instance: space.service_instance_by_name(service_instance_name),
      example: self,
      signature: app_signature
    )
    JSON.parse(test_app.get_env)
  end
end

RSpec.configure do |config|
  config.include(CfHelpers, :cf => true)
end
