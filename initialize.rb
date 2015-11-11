require 'tumblr_client'
require 'active_record'
require 'sentimental'
Dir["models/*.rb"].each {|file| require_relative file }
Dir["controllers/*.rb"].each {|file| require_relative file }

Tumblr.configure do |config|
	config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
	config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
	config.oauth_token = ENV['TUMBLR_OAUTH_TOKEN']
	config.oauth_token_secret = ENV['TUMBLR_OAUTH_TOKEN_SECRET']
end

ActiveRecord::Base.establish_connection(
	adapter: 'sqlite3',
	database: 'tumbot.db'
)
