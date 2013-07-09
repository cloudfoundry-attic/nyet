require "timeout"
require "cfoundry"

class AppWithStart
  def initialize(app, start_timeout, check_delay)
    @app = app
    @start_timeout = start_timeout
    @check_delay = check_delay
  end

  def start_and_wait
    staging_log = ""
    @app.start!(true) do |url|
      @app.stream_update_log(url) do |chunk|
        staging_log << chunk
      end if url
    end
    check_app_started
  rescue Exception
    puts "Staging app log:\n#{staging_log}"
    raise
  end

  private

  def check_app_started
    Timeout.timeout(@start_timeout) do
      begin
        sleep(@check_delay) until @app.running?
      rescue CFoundry::NotStaged
        sleep(@check_delay)
        retry
      end
    end
  end
end
