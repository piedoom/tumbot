require_relative 'bot.rb'
module Tumbot
	# the Client is basic logic.  It is not meant to show any processing,
	# just the flow of the application.
	class Client < Bot
		
		# check for new messages
		def check
			asks = get_asks
			asks.each do |ask|
				# place our ask in the database
				create_ask ask
				# reply to our ask
				reply_ask ask
			end
		end

		# reblog a random text post from a "following"
		def reblog_random_text_post
			if User.count > 0
				puts 'Getting a post to reblog...'.yellow
				post = get_text_post get_user, 1, 100
				if post
					if is_forbidden? post
						puts 'Post is forbidden to reblog'.red
						reblog_random_text_post
					else
						puts 'Post is good! Reblogging...'.yellow
						create_multiple_entries post.content
						reblog post
					end
				end
			end
		end

		def post_haiku
			puts 'Generating a haiku...'.yellow
			create_text_post(body: generate_haiku, title: generate_response(words: 3))
			puts "Posted haiku!\n".green
		end

	end
end
