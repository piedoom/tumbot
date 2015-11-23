# methods for the bot logic to inherit
require 'tumblr_client'
require 'sentimental'
require 'yaml'
require 'erb'
require 'marky_markov'
require 'sanitize'

module Tumbot
	class Bot	
	
		cnf_path = File.expand_path('config/config.yml')
		cnf = YAML.load(ERB.new(File.read(cnf_path)).result)
	
		@@client = Tumblr::Client.new
		@@username = cnf['username']
		@@sen = Sentimental.new(0)
		@@markov = MarkyMarkov::TemporaryDictionary.new(cnf['reply_randomness'])


		# get a user, random if no id is specified
		def get_user id
			return id ? User.find(id) : User.offset(rand(User.count)).first
		end

		# get a text post from a user, random if not min and max are specified
		def get_text_post user, min=0, max=0
			post = @@client.posts(user.username, type: 'text', limit: 1, pffset: (min..max))
			# if does not return empty array, create a new post
			post['posts'].empty? ? post = false : post = Textpost.new(post)
			return post
		end

		# return an array of ask objects ready to be created
		def get_asks
			asks = (@@client.submissions @@username, limit: 4)['posts']
			asks_list = []
			asks.each do |ask|
				user = create_user ask['asking_name']
				asks_list << Ask.new(sentiment: @@sen.get_score(ask['question']), user: user, text: Sanitize.fragment(ask['question']), tumblr_id: ask['id']) 
			end
			return asks_list
		end

		# create the ask object in the database
		def create_ask ask
			ask.save
		end

		def reply_ask ask, response=nil
			puts ask.inspect
			@@client.edit(@@username, id: ask.tumblr_id, answer: response ? response : generate_response, state: 'published')
		end

		def generate_response
			corpus = (Ask.all.map { |i| i.text }.join("\n")+'common I am we is the word there their.')
			@@markov.parse_string corpus
			return @@markov.generate_n_sentences rand(1..2)
		end

		# find or create a user
		def create_user username
			return User.find_or_create_by(username: username)			
		end

		# get the average sentiment
		def get_emotions memory=nil
			return Ask.limit(memory).reverse_order.average(:sentiment)
		end

		# reblog a post
		def reblog options
			@@client.reblog(@@doomybot, id: options[:id], reblog_key: options[:reblog_key], comment: options[:comment])
		end

		# see if post contains content we woudn't want to make light of
		def contains_forbidden_word? content
			blacklist = ['suicide','rape','don\'t reblog', 'dont reblog', 'depression', 'personal', 'lgbt', 'rape']
			blacklist.each { |word| return true if content.downcase.include? word }
		end

		# get a string of followers
		def get_following_string
			users = ''
			User.all.each do |user|
				users = users + "- <a href='#{user.username}.tumblr.com'>#{user.username}</a>\n"
			end
			return users
		end
	end
end
