require_relative 'initialize.rb'
tumbot = Tumbot::Bot.new

		puts 'Reblogging a post'
		tumbot.reblog_random_text_post
		sleep 20.minutes

