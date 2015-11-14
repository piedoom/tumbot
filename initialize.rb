require 'tumblr_client'
require 'active_record'
require 'sentimental'
require_relative 'bot.rb'
Dir["models/*.rb"].each {|file| require_relative file }

cfg = YAML.load(ERB.new(File.read('config/credentials.yml')).result)

Tumblr.configure do |config|
	config.consumer_key = cfg['consumer_key']
	config.consumer_secret = cfg['consumer_secret']
	config.oauth_token = cfg['oauth_token']
	config.oauth_token_secret = cfg['oauth_secret']
end

ActiveRecord::Base.establish_connection(
	adapter: 'sqlite3',
	database: 'tumbot.db'
)
