require 'fileutils'
require 'sanitize'
require 'marky_markov'

class AsksController
	
	def self.init
		#initialize our tumblr client
		@client = Tumblr::Client.new
		@markov = MarkyMarkov::TemporaryDictionary.new(1)
		@blog = ENV['TUMBLR_BOT_BLOG_NAME']
		#init the sentiment analysis tool
		Sentimental.load_defaults
		@sen = Sentimental.new(0)
		#init corpus so marky doesn't complain.  We need a few seed words if we don't have any.
		open('corpus.txt','w'){|f| f.puts 'this is some thing it is yes no'} unless File.file?('corpus.txt')
	end

	def self.create ask, user, sentiment
		#don't let people spam the same text over and over
		Ask.create_with(sentiment: sentiment).find_or_create_by(user: user, text: ask)
	end

	def self.check
		#loop over sumbmissions
		asks = (@client.submissions @blog, limit: 10)['posts'] 
		asks.each do |ask|
			#create a user if none exists
			current_user = UsersController.create ask['asking_name']
			self.create ask['question'], current_user, @sen.get_score(ask['question'])
		end
	end

	def self.index
		puts 'checking...'
		User.all.each do |user|
			puts user.username
			user.asks.each do |ask|
				puts ask.text
				puts ask.sentiment
			end
			puts
		end
	end

	def checkMessages
		#get messages as a hash
		messages = (@client.submissions @blog, limit: 10)['posts']
		#loop over messages
		messages.each do |message|	
			File.open('corpus.txt','a') do |f|
				#get all of the HTML out of our ask
			  input = Sanitize.fragment message['question']
				input = input + '.' if input[-1, 1] != '.' and input[-1, 1] != '!' and input[-1, 1] != '?'
				self.respondToAsk message['id']
			end
		end
	end

	def respondToAsk ask_id
		#generate our markov
		@markov.parse_file 'corpus.txt'
		response = Sanitize.fragment (@markov.generate_n_sentences Random.rand(1..3))
		@client.edit @blog, id: "#{ask_id}", answer: response, state: 'published'
		@markov.clear!
		puts 'published an ask!'
	end

	def followUser username
		#when asked a question, our bot will add a user to a list of followed individuals
		#because of the way tumblr is structured, sideblogs cannot have their own followers list
		#So, we will overcome this by just adding names to a text file
		File.open('following.txt','a') do |f|
			f.puts username
		end
	end

end
