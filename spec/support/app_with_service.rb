require "net/http"

class AppWithService
  def initialize(app, service_instance, namespace)
    @app = app
    @service_instance = service_instance
    @namespace = namespace
  end

  def get_env
    make_successful_request(:get, "/env")
  end

  def insert_value(key, value)
    make_successful_request(:post, service_key_path(key), value)
  end

  def get_value(key)
    make_successful_request(:get, service_key_path(key))
  end

  private

  def service_key_path(key)
    "/service/#{@namespace}/#{@service_instance.name}/#{key}"
  end

  def make_successful_request(*args)
    response = make_request(*args)
    raise "Received non-successful response (#{response.inspect})" \
      unless response.is_a?(Net::HTTPSuccess)
    response.body
  end

  def make_request(method, path, *args)
    # Net::HTTP will always return 404 if url includes scheme
    http = Net::HTTP.new(@app.url)
    puts "--- #{method.to_s.upcase} #{@app.url}#{path}"

    response = http.send(method, path, *args)
    puts "--- Response: #{response.inspect}"
    puts "    Body: #{response.body}"

    response
  end
end
