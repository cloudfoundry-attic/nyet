require 'bundler'
require 'uaa'
require 'uri'
require 'net/http'

Bundler.require(:default)

module NyetHelpers
  def logged_in_client
    raise 'Missing environment variables NYET_*' unless username && password && target

    client = CFoundry::Client.new(target)
    client.login(username, password)

    client
  end

  def username
    ENV['NYET_USERNAME']
  end

  def password
    ENV['NYET_PASSWORD']
  end

  def target
    ENV['NYET_TARGET']
  end

  def app_path(*parts)
    File.expand_path(File.join(File.dirname(__FILE__), '..',  'apps', *parts))
  end

  def with_org(org_name)
    org_guid = create_org(org_name)
    yield
  ensure
    delete_org(org_guid)
  end

  def with_model(model)
    model.create!
    yield
  ensure
    model.delete!
  end

  def clean_up_previous_run(client, name)
    app = client.app_by_name(name)
    app.delete! if app

    route = client.route_by_host(name)
    route.delete! if route
  end

  def auth_token
    uaa_target = target.gsub(/\/\/\w+/, '//uaa')
    token_issuer = CF::UAA::TokenIssuer.new(uaa_target, 'cf')
    token = token_issuer.implicit_grant_with_creds(username: username, password: password)
    {"Authorization" => "bearer #{token.info['access_token']}"}
  end

  def paid_quota_definition
    target_uri = URI(target)
    http = Net::HTTP.new(target_uri.host, target_uri.port)
    response = http.request_get('/v2/quota_definitions', auth_token)
    quotas = JSON.parse(response.body)
    paid_quota = quotas["resources"].find { |q| q["entity"]["name"] == "paid" }
    paid_quota["metadata"]["guid"]
  end

  def create_org(org_name)
    target_uri = URI(target)
    http = Net::HTTP.new(target_uri.host, target_uri.port)
    data = JSON.dump(
      {
        "name" => org_name,
        "quota_definition_guid" => paid_quota_definition
      }
    )
    response = http.post('/v2/organizations', data, auth_token)
    JSON.parse(response.body)["metadata"]["guid"]
  end

  def delete_org(org_guid)
    return unless org_guid
    target_uri = URI(target)
    http = Net::HTTP.new(target_uri.host, target_uri.port)
    response = http.delete("/v2/organizations/#{org_guid}", auth_token)
  end
end