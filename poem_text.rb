require_relative 'initialize.rb'
require_relative 'tumbot/bot.rb'

a = Tumbot::Bot.new

a.generate_haiku # 'this is an example string'
