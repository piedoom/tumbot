require 'marky_markov'
require 'yaml'
require 'erb'

#settings class for our tumblr bot
module Tumbot 
	class Bot
		def initialize
			@cnf = YAML.load(ERB.new(File.read('config/config.yml')).result)
			# initialize our tumblr client
			@client = Tumblr::Client.new
			@markov = MarkyMarkov::TemporaryDictionary.new(@cnf['reply_randomness'])
			@blacklist = ['suicide','don\'t reblog', 'dont reblog', 'tw', 'depression', 'personal', 'lgbt', 'rape']
			# init the sentiment analysis tool
			Sentimental.load_defaults
			@sen = Sentimental.new(0)
			# init corpus so marky doesn't complain.  
			# We need a few seed words if we don't have any.
			open('corpus.txt','w'){|f| f.puts 'this is some thing it is yes no'} unless File.file?('corpus.txt')
		end
	
		def create ask, user, sentiment
				# add punctuation
				ask += '.' if ask[-1,1] !~ /(\!|\.|\?)/
				# don't let people spam the same text over and over
				Ask.create_with(sentiment: sentiment).find_or_create_by(user: user, text: ask)
		end
	
		def check
			# loop over sumbmissions
			asks = (@client.submissions @cnf['username'], limit: @cnf['ask_get_limit'])['posts'] 
			asks.each do |ask|
				# create a user if none exists
				current_user = create_user ask['asking_name']
				self.create ask['question'], current_user, @sen.get_score(ask['question'])
				self.reply ask['id'] 
			end
		end
	
		def reply ask_id
			# build our dictionary
			corpus = Ask.all.map { |i| i.text }.join("\n")
			@markov.parse_string corpus
			response = @markov.generate_n_sentences Random.rand(@cnf['ask_min_sentences']..@cnf['ask_max_sentences'])
			# publish ask
			@client.edit @cnf['username'], id: "#{ask_id}", answer: response, state: 'published'
			@markov.clear!
			puts 'published an ask!'
		end

 	 # find or create a user
		def create_user username
			User.find_or_create_by(username: username)
		end

		# get emotional state
		def get_emotions
			Ask.limit(@cnf['emotional_memory']).reverse_order.average(:sentiment)
		end

		# reblog a random user's post with a caption
		def reblog_random_text_post 
			if User.count > 3
					user = get_random_user
					post = get_text_post user, 1, 100
					reblog(post.id, post.reblog_key, generate_response) if okay_to_reblog? post.body
			end
		end

		# will return false if a forbidden word is used
		# this is to prevent private posts from being reblogged 
		def okay_to_reblog? content
			@blacklist.each do |word|
				return true if content.downcase.include? word
			end
		end

		def reblog id, reblog_key, comment
			@client.reblog(@cnf['username'], id: "#{id}", reblog_key: "#{reblog_key}", comment: "#{comment}")
		end

		#returns string of a randomized response
		def generate_response
			corpus = Ask.all.map { |i| i.text }.join("\n")
			@markov.parse_string corpus
			return @markov.generate_n_sentences Random.rand(@cnf['ask_min_sentences']..@cnf['ask_max_sentences'])
		end

		def get_random_user
			return User.offset(rand(User.count)).first
		end

		# get a text post from a blog
		def get_text_post user, rand_min, rand_max
			post = @client.posts(user.username, type: 'text', limit: 1, offset: Random.rand(rand_min..rand_max))
			return TextPost.new(post)
		end
	end
end
