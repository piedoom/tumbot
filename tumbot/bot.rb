# methods for the bot logic to inherit
require 'tumblr_client'
require 'sentimental'
require 'yaml'
require 'erb'
require 'marky_markov'
require 'sanitize'
require 'colorize'
require 'mini_magick'
require 'pxlsrt'

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

		# get an image url, random if no id is specified
		def get_image id=nil
			return id ? Image.find(id) : Image.offset(rand(Image.count)).first
		end

		def download_image url
			dirname = File.dirname('images')
			FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
			image = MiniMagick::Image.open(url)
			image.format 'png' if image.type != 'PNG'
		 	filename = "images/#{Time.now.to_i}.png"
			image.write filename
			return filename
		end

		def rb
			return [true,false].sample
		end

		# pixel sort an image
		def sort_image path
			type = rand(0..3)
			diagonal = [true,false].sample
			case type
			when 0
				puts 'Generating brute sort...'.blue
				Pxlsrt::Brute.brute(path, diagonal: diagonal, middle: rb, vertical: rb).save(path)
			when 1
				puts 'Generating smart sort...'.blue
				Pxlsrt::Smart.smart(path, threshold: rand(100..200), diagonal: diagonal).save(path)
			when 2
				puts 'Generating kim sort...'.blue
				Pxlsrt::Kim.kim(path).save(path)
			when 3
				puts 'Generating seed sort...'.blue
				Pxlsrt::Seed.seed(path, threshold: rand(0.1..10), distance: rand(20..50)).save(path)
			end
			puts 'Pixel sort successful, uploading...'.yellow
			return path
		end

		def post_pixelsort
			# gets a random image, downloads it, and processes it
			# image is the path to our image
			image = (get_image)
			image_path = sort_image(download_image(image.url))
			create_photo_post(path: image_path, caption: generate_response)
		end

		# get a text post from a user, random if not min and max are specified
		def get_text_post user, min=0, max=0
			post = @@client.posts(user.username, type: 'text', limit: 1, offset: rand(min..max))
			# if does not return empty array, create a new post
			if post
				post['posts'].empty? ? post_get = false : post_get = TextPost.new(post)
			end
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
			text = text.rstrip
			return text + '.' if text[-1..-1] !~ /(\!|\.|\?)/
		end

		def create_text_post block=nil
			@@client.text(@@username, title: block[:title], body: block[:body])
		end

		def create_photo_post block=nil
			@@client.photo(@@username, {data: block[:path], caption: block[:caption]})
			puts "Published a photo post!\n".green
		end

		def generate_response options=nil
			corpus = (Ask.all.map { |i| i.text }.join("\n")+'common I am we is the word there their.')
			@@markov.parse_string corpus
			return @@markov.generate_n_sentences rand(1..2) if !options
			return @@markov.generate_n_words options[:words] if options[:words]
			return @@markov.generate_n_sentences options[:sentences] if options[:sentences]
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

		# generate a poem
		def generate_haiku
			# get enough words so that if they all had 1 syl, it would work
			# this isn't perfect
			# sometimes the haiku will have one extra syllable

			base = generate_response(words: 17)
			hash = tokenize_syllables base
			final = ""
			syllable_count = 0

			hash.each do |k,v|
				if syllable_count < 17
					final += "#{k} "
					syllable_count += v
					final += "\n" if syllable_count == 5 || syllable_count == 12
				end
			end
			
			return final
		end

		# take in a string and return a dictionary of each word and their syllables
		def tokenize_syllables words
			words_array = words.gsub(/\s+/m, ' ').strip.split(" ")
			final_hash = Hash.new
			words_array.each do |word|
				word = sanitize(word)
				final_hash.store(word,count_syllables(word))
			end
			return final_hash
		end

		def count_syllables word
			word.downcase!
			return 1 if word.length <= 3
			word.sub!(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, '')
			word.sub!(/^y/, '')
		  return word.scan(/[aeiouy]{1,2}/).size
		end
	end
end
