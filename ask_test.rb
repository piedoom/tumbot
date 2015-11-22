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
often.join
less_often.join
