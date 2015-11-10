require 'fileutils'
require 'sanitize'
require 'marky_markov'

class Manager
	def initialize
		#initialize our tumblr client
		@client = Tumblr::Client.new
		@markov = MarkyMarkov::TemporaryDictionary.new(1)
		@blog = ENV['TUMBLR_BOT_BLOG_NAME']
		#init corpus so marky doesn't complain.  We need a few seed words if we don't have any.
		open('corpus.txt','w'){|f| f.puts 'this is some thing it is yes no'} unless File.file?('corpus.txt')
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

end
