require 'tumblr_client'

Tumblr.configure do |config|
	config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
	config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
	config.oauth_token = ENV['TUMBLR_OAUTH_TOKEN']
	config.oauth_token_secret = ENV['TUMBLR_OAUTH_TOKEN_SECRET']
end
