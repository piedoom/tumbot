require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
tumbot = Tumbot::Client.new

#tumbot.reblog_random_text_post
puts 'Doomybot started!'
often = Thread.new do
	loop do
		puts 'checking for posts'
		tumbot.check
		sleep 6	
	end
end
less_often = Thread.new do
	loop do
		#puts 'Reblogging a post'
		#tumbot.reblog_random_text_post
		#sleep 900 # 15 minutes
	end
end
often.join
less_often.join
