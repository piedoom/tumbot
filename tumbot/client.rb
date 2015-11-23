require_relative 'bot.rb'
module Tumbot
	# the Client is basic logic.  It is not meant to show any processing,
	# just the flow of the application.
	class Client < Bot
		def check
			asks = get_asks
			asks.each do |ask|
				# place our ask in the database
				create_ask ask
				# reply to our ask
				reply_ask ask
			end
		end
	end
end
