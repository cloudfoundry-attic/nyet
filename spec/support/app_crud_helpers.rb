CHECK_DELAY = 0.25.freeze
ROUTING_TIMEOUT = 60.freeze

APPS = {
    "ruby" => "ruby/simple",
    "java" => "java/JavaTinyApp-1.1.war"
}

module AppCrudHelpers
  def deploy_app(app, path)
    puts "starting #{__method__} (#{Time.now})"
    app.upload(File.expand_path("../../../apps/#{path}", __FILE__))
  end

  def start_app_and_wait_until_up(app)
    puts "starting #{__method__} (#{Time.now})"
    staging_log = ""
    app.start! do |url|
      app.stream_update_log(url) do |chunk|
        staging_log << chunk
      end if url
    end

    wait_until_app_started(app)
  rescue
    puts "Staging app log:\n#{staging_log}"
    raise
  end

  def wait_until_app_started(app)
    puts "starting #{__method__} (#{Time.now})"
    sleep(CHECK_DELAY) until app.running?
  rescue CFoundry::NotStaged
    sleep(CHECK_DELAY)
    retry
  end

  def page_content
    app_uri = URI("http://#{route.host}.#{route.domain.name}")
    Net::HTTP.get(app_uri)
  end
end