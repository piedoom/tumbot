require 'marky_markov'
require 'yaml'
require 'erb'
require_relative 'helper.rb'

#settings class for our tumblr bot
module Tumbot
	cnf = YAML.load(ERB.new(File.read('config/config.yml')).result)
	$USERNAME = cnf['username']
	$REPLY_RANDOMNESS = cnf['reply_randomness']
	$ASK_GET_LIMIT = cnf['ask_get_limit']
	$ASK_MIN_SENTENCES = cnf['ask_min_sentences']
	$ASK_MAX_SENTENCES = cnf['ask_max_sentences']
	$EMOTIONAL_MEMORY = cnf['emotional_memory']
	$SEN = Sentimental.new(0)

	class Bot < Helper
		def initialize
			$client = Tumblr::Client.new
			# initialize our tumblr client
			@markov = MarkyMarkov::TemporaryDictionary.new($REPLY_RANDOMNESS)
			# init the sentiment analysis tool
			Sentimental.load_defaults
			@sen = Sentimental.new(0)
		end
	
		def check
			# loop over sumbmissions
			asks = ($client.submissions $USERNAME, limit: $ASK_GET_LIMIT)['posts'] 
			asks.each do |ask|
				# create a user if none exists
				current_user = create_user ask['asking_name']
				create_ask ask['question'], current_user
				reply ask['id']
			end
		end
	
		def reply ask_id
			# build our dictionary
			$client.edit $USERNAME, id: "#{ask_id}", answer: generate_response, state: 'published'
			@markov.clear!
			puts 'published an ask!'
		end

 	 # find or create a user
		def create_user username
			User.find_or_create_by(username: username)
		end

		# reblog a random user's post with a caption
		def reblog_random_text_post 
			if User.count > 3
				user = get_random_user
				post = get_text_post user, 1, 1
				if post != false
					if okay_to_reblog? post.body
						reblog(id: post.id, reblog_key: post.reblog_key, comment: generate_response)
					else
					  reblog_random_text_post
					end
				else
					reblog_random_text_post
				end
			end
		end

		#returns string of a randomized response
		def generate_response
			corpus = Ask.all.map { |i| i.text }.join("\n")
			@markov.parse_string corpus
			return @markov.generate_n_sentences Random.rand($ASK_MIN_SENTENCES..$ASK_MAX_SENTENCES)
		end
	end
end
