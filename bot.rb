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
			# init the sentiment analysis tool
			Sentimental.load_defaults
			@sen = Sentimental.new(0)
			# init corpus so marky doesn't complain.  We need a few seed words if we don't have any.
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
				current_user = createUser ask['asking_name']
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

 	 #find or create a user
		def createUser username
			User.find_or_create_by(username: username)
		end

		#get emotional state
		def getEmotions
			Ask.limit(@cnf['emotional_memory']).reverse_order.average(:sentiment)
		end
			
	end
end
