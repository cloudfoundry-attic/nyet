require 'json'
require 'uri'
require 'forwardable'
require 'bundler'

Bundler.require

get '/env' do
  ENV['VCAP_SERVICES']
end

get '/rack/env' do
  ENV['RACK_ENV']
end

post '/service/pg/:service_name/:key' do
  value = request.env["rack.input"].read
  client = load_postgresql(params[:service_name])

  result = client.query("select * from data_values where id = '#{params[:key]}'")
  if result.count > 0
    client.query("update data_values set data_value='#{value}' where id = '#{params[:key]}'")
  else
    client.query("insert into data_values (id, data_value) values('#{params[:key]}','#{value}');")
  end
  client.close
  value
end

get '/service/pg/:service_name/:key' do
  client = load_postgresql(params[:service_name])
  value = client.query("select data_value from data_values where id = '#{params[:key]}'").first['data_value']
  client.close
  value
end

class DatabaseCredentials
  extend Forwardable
  def_delegators :@uri, :host, :port, :user, :password
  def initialize(uri)
    @uri = URI(uri)
  end

  def database_name
    @uri.path.slice(1..-1)
  end
end

def load_postgresql(service_name)
  postgresql_service = load_service_by_name(service_name)
  uri = DatabaseCredentials.new postgresql_service.fetch('uri')
  client = PGconn.open(uri.host, uri.port, dbname: uri.database_name, user: uri.user, password: uri.password)
  if client.query("select * from pg_catalog.pg_class where relname = 'data_values';").num_tuples() < 1
    client.query("create table data_values (id varchar(20), data_value varchar(20));")
  end
  client
end

def load_service_by_name(service_name)
  services = JSON.parse(ENV['VCAP_SERVICES'])
  services.values.each do |v|
    v.each do |s|
      if s["name"] == service_name
        return s["credentials"]
      end
    end
  end
  raise "service with name #{service_name} not found in bound services"
end