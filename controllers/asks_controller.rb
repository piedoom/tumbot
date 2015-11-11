require 'fileutils'
require 'sanitize'
require 'marky_markov'

class AsksController
	
	def initialize
		#initialize our tumblr client
		@client = Tumblr::Client.new
		@markov = MarkyMarkov::TemporaryDictionary.new(1)
		@blog = ENV['TUMBLR_BOT_BLOG_NAME']
		@semaphore = Mutex.new
		#init the sentiment analysis tool
		Sentimental.load_defaults
		@sen = Sentimental.new(0)
		#init corpus so marky doesn't complain.  We need a few seed words if we don't have any.
		open('corpus.txt','w'){|f| f.puts 'this is some thing it is yes no'} unless File.file?('corpus.txt')
	end

	def create ask, user, sentiment
			#add punctuation
			ask = ask + '.' if ask[-1, 1] != '.' and ask[-1, 1] != '!' and ask[-1, 1] != '?'
			#don't let people spam the same text over and over
			Ask.create_with(sentiment: sentiment).find_or_create_by(user: user, text: ask)
	end

	def check
		#loop over sumbmissions
		asks = (@client.submissions @blog, limit: 10)['posts'] 
		asks.each do |ask|
			#create a user if none exists
			current_user = UsersController.create ask['asking_name']
			self.create ask['question'], current_user, @sen.get_score(ask['question'])
			self.reply ask['id'] 
		end
	end

	def reply ask_id
		#build our dictionary
		corpus = Ask.all.map { |i| i.text }.join("\n")
		@markov.parse_string corpus
		response = @markov.generate_n_sentences Random.rand(1..3)
		#publish ask
		@client.edit @blog, id: "#{ask_id}", answer: response, state: 'published'
		@markov.clear!
		puts 'published an ask!'
	end

	def index
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


	def followUser username
		#when asked a question, our bot will add a user to a list of followed individuals
		#because of the way tumblr is structured, sideblogs cannot have their own followers list
		#So, we will overcome this by just adding names to a text file
		File.open('following.txt','a') do |f|
			f.puts username
		end
	end

end
