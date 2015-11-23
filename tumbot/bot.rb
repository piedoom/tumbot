# methods for the bot logic to inherit
require 'tumblr_client'
require 'sentimental'
require 'yaml'
require 'erb'
require 'marky_markov'
require 'sanitize'
require 'colorize'

module Tumbot
	class Bot	
	
		cnf_path = File.expand_path('config/config.yml')
		cnf = YAML.load(ERB.new(File.read(cnf_path)).result)
	
		@@client = Tumblr::Client.new
		@@username = cnf['username']
		Sentimental.load_defaults
		@@sen = Sentimental.new(0)
		@@markov = MarkyMarkov::TemporaryDictionary.new(cnf['reply_randomness'])


		# get a user, random if no id is specified
		def get_user id=nil
			return id ? User.find(id) : User.offset(rand(User.count)).first
		end

		# get a text post from a user, random if not min and max are specified
		def get_text_post user, min=0, max=0
			post = @@client.posts(user.username, type: 'text', limit: 1, offset: rand(min..max))
			# if does not return empty array, create a new post
			post['posts'].empty? ? post_get = false : post_get = TextPost.new(post)
			return post_get
		end

		# return an array of ask objects ready to be created
		def get_asks
			asks = (@@client.submissions @@username, limit: 4)['posts']
			asks_list = []
			asks.each do |ask|
				user = create_user ask['asking_name']
				question = sanitize ask['question']
				asks_list << Ask.new(sentiment: @@sen.get_score(question), user: user, text: question, tumblr_id: ask['id']) 
			end
			return asks_list
		end

		def sanitize content
			return Sanitize.fragment(content)
		end

		# create the ask object in the database
		def create_ask ask
			# add punctuation
			ask.text = add_punctuation ask.text
			if ask.save
				puts "Saved ask from #{ask.user.username}".yellow
			else
				puts "Problem saving ask from #{ask.user.username}".red
			end
		end

		def reply_ask ask, response=nil
			@@client.edit(@@username, id: ask.tumblr_id, answer: response ? response : generate_response, state: 'published')
			puts "Published ask from #{ask.user.username}!\n".green
		end
		
		# create ask objects in database
		# these asks have no user, and are passed in as an array of strings 
		def create_multiple_entries asks
			asks.each do |ask|
				ask = sanitize ask
				ask = add_punctuation ask
				Ask.create(user: nil, text: ask, sentiment: @@sen.get_score(ask))
			end
			puts "Created multiple asks!".green
		end
		
		def add_punctuation text
			return text + '.' if text[-1..1] !~ /(\!|\.|\?)/
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
		def reblog post
			#@@client.reblog(@@doomybot, id: options[:id], reblog_key: options[:reblog_key], comment: options[:comment])
			#puts post.inspect
			@@client.reblog(@@username, id: post.id, reblog_key: post.reblog_key, comment: generate_response)
			puts "Reblogged post #{post.id}!\n".green
		end

		# see if post contains content we woudn't want to make light of
		def is_forbidden? content
			blacklist = ['suicide','rape','don\'t reblog', 'dont reblog', 'depression', 'personal', 'lgbt', 'rape']
			blacklist.each do |word| 
				if content.body.downcase.include? word
					return true
				end
			end
			return false
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
