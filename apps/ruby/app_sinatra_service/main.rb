require 'json'
require 'uri'
require 'forwardable'
require 'bundler'
require "mail"

Bundler.require

after do
  headers["Services-Nyet-App"]="true"
end

get '/env' do
  ENV['VCAP_SERVICES']
end

get '/rack/env' do
  ENV['RACK_ENV']
end

error do
  "Error: #{env['sinatra.error']}\n#{env['sinatra.error'].backtrace.join("\n")}"
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

get '/service/mysql/:service_name/:key' do
  client = load_mysql(params[:service_name])
  value = client.query("select data_value from data_values where id = '#{params[:key]}'").first['data_value']
  client.close
  value
end

post '/service/mysql/:service_name/:key' do
  value = request.env["rack.input"].read
  client = load_mysql(params[:service_name])

  result = client.query("select * from data_values where id = '#{params[:key]}'")
  if result.count > 0
    client.query("update data_values set data_value='#{value}' where id = '#{params[:key]}'")
  else
    client.query("insert into data_values (id, data_value) values('#{params[:key]}','#{value}');")
  end
  client.close
  value
end

post '/service/amqp/:service_name/:key' do
  value = request.env["rack.input"].read
  client = load_amqp(params[:service_name])

  queue = client.queue(params[:key])
  queue.publish(value)

  client.stop
  value
end

get '/service/amqp/:service_name/:key' do
  client = load_amqp(params[:service_name])

  queue = client.queue(params[:key])
  value = queue.pop

  client.stop
  value
end

post '/service/redis/:service_name/:key' do
  value = request.env["rack.input"].read
  client = load_redis(params[:service_name])

  client.set(params[:key], value)

  client.quit
  value
end

get '/service/redis/:service_name/:key' do
  client = load_redis(params[:service_name])

  value = client.get(params[:key])

  client.quit
  value
end

post '/service/mongodb/:service_name/:key' do
  value = request.env["rack.input"].read
  db = load_mongodb(params[:service_name])

  collection = db['my_collection']
  document = { '_id' => params[:key], 'value' => value }
  collection.update({ '_id' => params[:key] }, document, :upsert => true)

  value
end

get '/service/mongodb/:service_name/:key' do
  db = load_mongodb(params[:service_name])

  collection = db['my_collection']
  document = collection.find('_id' => params[:key]).to_a.first
  value = document['value']

  value
end

post '/service/smtp/:service_name' do
  prms = params
  load_smtp(prms[:service_name])
  mail = Mail.deliver do
    from "nyettests@cloudfoundry.com"
    to prms[:to] or raise "Missing require form param 'to'"
    subject prms[:subject] || "Default subject"
    body prms[:body] || "Default body"
  end
  mail.inspect
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

def load_mysql(service_name)
  mysql_service = load_service_by_name(service_name)
  client = Mysql2::Client.new(
    :host     => mysql_service['hostname'],
    :username => mysql_service['username'],
    :port     => mysql_service['port'].to_i,
    :password => mysql_service['password'],
    :database => mysql_service['name']
  )
  result = client.query("SELECT table_name FROM information_schema.tables WHERE table_name = 'data_values'")
  client.query("CREATE TABLE IF NOT EXISTS data_values ( id VARCHAR(20), data_value VARCHAR(20)); ") if result.count != 1
  client
end

def load_amqp(service_name)
  amqp_service = load_service_by_name(service_name)
  amqp_uri = URI(amqp_service.fetch('uri'))
  Carrot.new(:host => amqp_uri.host, :port => amqp_uri.port, :user => amqp_uri.user, :pass => amqp_uri.password, :vhost => amqp_uri.path[1..-1])
end

def load_smtp(service_name)
  sendgrid_service = load_service_by_name(service_name)
  Mail.defaults do
    delivery_method :smtp, { :address   => sendgrid_service.fetch('hostname'),
                             :port      => 587,
                             :domain    => "cloudfoundry.com",
                             :user_name => sendgrid_service.fetch('username'),
                             :password => sendgrid_service.fetch('password'),
                             :authentication => 'plain',
                             :enable_starttls_auto => true }
  end
end

def load_redis(service_name)
  redis_service = load_service_by_name(service_name)
  Redis.new(:host => redis_service['hostname'], :port => redis_service['port'].to_i, :password => redis_service['password'])
end

def load_mongodb(service_name)
  mongodb_service = load_service_by_name(service_name)
  uri = URI(mongodb_service.fetch('uri'))
  conn = Mongo::Connection.new(uri.host, uri.port)
  db = conn[uri.path[1..-1]]
  db.authenticate(uri.user, uri.password)
  db
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
