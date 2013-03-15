require 'bundler'

Bundler.require(:default)

def logged_in_client
  username = ENV['NYET_USERNAME']
  password = ENV['NYET_PASSWORD']
  target = ENV['NYET_TARGET']

  client = CFoundry::Client.new(target)
  client.login(username, password)

  client
end

def app_path(*parts)
  File.expand_path(File.join(File.dirname(__FILE__), '..',  'apps', *parts))
end