require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
require 'timeout'
tumbot = Tumbot::Client.new

#tumbot.reblog_random_text_post
puts 'Doomybot started!'
often = Thread.new do
	puts 'checking for posts'
	loop do
		tumbot.check
		sleep 6	
	end
end
less_often = Thread.new do
	loop do
		tumbot.reblog_random_text_post
		sleep 900 # 15 minutes
	end
end
rarely = Thread.new do
	loop do
		tumbot.post_haiku
		sleep 7200 # two hours
	end
end
cmd = Thread.new do
	loop do
		# control with command line
		command = gets.chomp
		puts command
	end
end
often.join
less_often.join
rarely.join
cmd.join
