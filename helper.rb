require 'sanitize'
require_relative 'models/text_post.rb'
module Tumbot
	class Helper
		# get a random user from the database
		def get_random_user
			return User.offset(rand(User.count)).first
		end

		# gets a text post
		# user is a User model
		# rand_min and rand_max can both be 0 for no randomness
		def get_text_post user, rand_min=0, rand_max=0
			post = $client.posts(user.username, type: 'text', limit: 1, offset: rand(rand_min..rand_max))
			if post['posts'] != []
				post = TextPost.new(post)
				return post
			end
		  return false
		end

		def get_emotions
			Ask.limit($EMOTIONAL_MEMORY).reverse_order.average(:sentiment)
		end

		def reblog options
			$client.reblog($USERNAME, id: options[:id], reblog_key: options[:reblog_key], comment: options[:comment])
			puts 'Finished reblogging.'
		end

		def okay_to_reblog? content
			blacklist = ['suicide','don\'t reblog', 'dont reblog', 'depression', 'personal', 'lgbt', 'rape']
			blacklist.each do |word|
				 if content.downcase.include? word
					 return false
				 end
			 end
		end
	end
end
