require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
tumbot = Tumbot::Client.new

#tumbot.reblog_random_text_post
puts 'Doomybot started!'
	loop do
		tumbot.reblog_random_text_post
		sleep 900 # 15 minutes
	end
