require_relative 'initialize.rb'
tumbot = Tumbot::Bot.new

#tumbot.reblog_random_text_post
puts 'Doomybot started!'
often = Thread.new do
	loop do
		tumbot.check
		sleep 6	
	end
end
less_often = Thread.new do
	loop do
		puts 'Reblogging a post'
		tumbot.reblog_random_text_post
		sleep 900 # 15 minutes
	end
end
often.join
less_often.join
tumbot.reblog_random_text_post
