require 'active_record'
require 'marky_markov'
require 'tumblr_client'
require 'sentimental'
require 'nokogiri'
require 'mini_magick'
require 'pxlsrt'

require_relative 'doomybot/models/user'
require_relative 'doomybot/models/ask'
require_relative 'doomybot/models/text_post'
require_relative 'doomybot/models/image'

require_relative 'ext/string'
require_relative 'doomybot/client'


module Doomybot

  ROOT_PATH = Dir.pwd
  USERNAME = 'doomybottest'

  # init tumblr
  Tumblr.configure do |config|
    config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
    config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
    config.oauth_token = ENV['TUMBLR_OAUTH_TOKEN']
    config.oauth_token_secret = ENV['TUMBLR_OAUTH_TOKEN_SECRET']
  end

  # init database
  ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'Doomybot.db'
  )

end