require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
tumbot = Tumbot::Client.new

#tumbot.reblog_random_text_post
puts 'Doomybot started!'
	loop do
		if Image.count > 0
			tumbot.post_pixelsort
			sleep 5
		end
	end
