# the bot will interface with most of our functionality
module Doomybot
  module Client

    # constants

    # keeps marky happy even if there are no entries
    BASE_TEXT = 'common I am we is the word there their.'

    # gets all asks and replies to them
    def self.get_and_reply_to_asks
      # init tumblr client
      client = Tumblr::Client.new
      # get array of asks
      asks = (client.submissions USERNAME, limit: 6)['posts']
      # create our ClientAsk objects
      asks_list = []
      asks.each do |ask|
        # create the asks in a database and add them to an array to return
        asks_list << Ask.create(sentiment: (ask['question']).sentiments,
                             user: User.find_or_create_by(username: ask['asking_name']),
                             text: ask['question'].add_punctuation,
                             tumblr_id: ask['id'])
      end
      reply_to_asks(asks_list) if asks_list.count > 0
    end

    # replys to asks.  Takes an array of Ask objects
    def self.reply_to_asks asks
      # init tumblr client
      client = Tumblr::Client.new

      ##### TEMPORARY PATCH TO KEEP ASK FLOODS ######
      # will start to queue asks if they are less than a minute apart #
      # YES this WILL chain #

      last_ask = Ask.find(asks.first.id - 1)
      post_ok = last_ask.created_at < (Time.now - 30.seconds)
      #post_ok ? state = 'published' : state = 'queue'
      state = 'published'

      #########################
	

      asks.each do |ask|
        client.edit(USERNAME,
                         id: ask.tumblr_id,
                         answer: generate_response,
                         state: state,
                         is_private: true,
                         tags: "feeling #{get_sentiment(to_string: true)}")
        puts "Published ask from #{ask.user.username}!\n"
      end
    end

    def self.get_random_user
        offset = rand(User.count)
        return User.offset(offset).first
    end

    # reblog a random text post
    def self.reblog_random_text_post
      client = Tumblr::Client.new
      if User.count > 0
        # get a random user
        offset = rand(User.count)
        user = User.offset(offset).first
        # get a random post from the user
        post_hash = client.posts(user.username,
                            type: 'text',
                            limit: 1,
                            offset: rand(1..100))
        puts post_hash
        if post_hash['status'] == 404
          puts 'Nothing found for that user.'
          # try again if no user posts are found
          reblog_random_text_post
        else
          # create a new TextPost object with our info
          post = TextPost.new(post_hash)
          # add the content of our text post to the database of asks
          post.content.each do |ask|
            Ask.create(sentiment: ask.sentiments,
                       user: nil,
                       text: ask.add_punctuation,
                       tumblr_id: nil)
          end
          # finally reblog the post
          client.reblog(USERNAME,
                        id: post.id,
                        reblog_key: post.reblog_key,
                        comment: generate_response,
                        tags: "feeling #{get_sentiment(to_string: true)}")
        end
      end
    end

    def self.post_text_post
        puts 'creating original text post'
        client = Tumblr::Client.new
        text = generate_response
        title = generate_response(sentences: 1)
        client.text(USERNAME, title: title, body: text, tags: "feeling #{get_sentiment(to_string: true)}, text")    
    end

    def self.post_chat_post
        puts "generating conversation"
        users = [get_random_user, get_random_user]
        
        # how many times to go back and forth
        quips = rand(1..2)

        client = Tumblr::Client.new
        
        conversation = ""
        quips.times do
            users.each do |user|
                conversation += "#{user.username}: #{generate_response(sentences: 1)}\n"
            end
        end
        client.chat(USERNAME, conversation: conversation, tags: "feeling #{get_sentiment(to_string: true)}, #{users[0].username}, #{users[1].username}, chat, fanfic")
    end

    # posts a pixelsorted image
    def self.post_pixelsort
      if Image.count > 0
        client = Tumblr::Client.new
        # get a random image
        offset = rand(Image.count)
        image = Image.offset(offset).first
        path = download_image(image.url)
        path = sort_image(path)
        client.photo(USERNAME, {data: path, caption: generate_response})
      end
    end

    private

    def self.download_image url
      # download image
      dirname = "#{ROOT_PATH}/images"
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      # open image and save it
      image = MiniMagick::Image.open(url)
      image.resize("640x")
      image.format 'png' if image.type != 'PNG'
      filename = "images/#{Time.now.to_i}.png"
      image.write filename
      return filename
    end

    # generate a markov response
    def self.generate_response(sentences: nil)
      # get our dictionary
      markov = MarkyMarkov::TemporaryDictionary.new(2)
      sentiment = get_sentiment
      # get our entries to choose from based on if the robot is happy or sad
      sentiment >= 0 ? sql = "sentiment >= 0" : sql = "sentiment < 0"
      corpus = (Ask.where(sql).map { |i| i.text }.join("\n") + BASE_TEXT )
      # set the amount of sentences to generate
      sentences ||= rand(1..2)
      markov.parse_string corpus
      gen = markov.generate_n_sentences sentences
      markov.clear!
      return gen
    end

    # returns a number or string
    def self.get_sentiment(memory: 10, to_string: false)
      average_sum = 0
      #Ask.last(memory).each do |ask|
      # instead of a memory, we now get asks counted at the start of every day, so Doomybot's emotions are less sporadic
      Ask.where("created_at >= ?", Time.now.beginning_of_day).each do |ask|
        average_sum += ask.sentiment.to_f
      end
      number = average_sum / memory

      # return a string or number depending
      if to_string
        # probably better accomplished with yaml or something
	os = 2 # offset for emotions.  bigger numbers make emotions fluctuate less
        if number >= 0 * os and number < 0.1 * os
          state = 'ok'
        elsif number >= 0.1 * os and number < 0.2 * os
          state = 'fine'
        elsif number >= 0.2 * os and number < 0.3 * os
          state = 'pretty ok'
        elsif number >= 0.3 * os and number < 0.4 * os
          state = 'good'
        elsif number >= 0.4 * os and number < 0.5 * os
          state = 'great'
        elsif number >= 0.5 * os and number < 0.6 * os
          state = 'happy'
        elsif number >= 0.6 * os and number < 0.7 * os
          state = 'really happy'
        elsif number >= 0.7 * os and number < 0.8 * os
          state = 'fantastic'
        elsif number >= 0.8 * os
          state = 'ASCENDED'
        elsif number < 0 * os and number > -0.1 * os
          state = 'eh'
        elsif number <= -0.1 * os and number > -0.2 * os
          state = 'not great'
        elsif number <= -0.2 * os and number > -0.3 * os
          state = 'not good'
        elsif number <= -0.3 * os and number > -0.4 * os
          state = 'sad'
        elsif number <= -0.4 * os and number > -0.5 * os
          state = 'awful'
        elsif number <= -0.5 * os and number > -0.6 * os
          state = 'terrible'
        elsif number <= -0.6 * os and number > -0.7 * os
          state = 'depressed'
        elsif number <= -0.7 * os and number > -0.8 * os
          state = 'worse than ever'
        elsif number <= -0.8 * os
          state = 'DREAD AND DEATH'
        end
        return state
      else
        return number
      end

      number >= 0 ? emotional_state = 'happy' : emotional_state = 'sad'
      to_string ? emotional_state : number
    end

    # return random true or false
    def self.rb
      return [true,false].sample
    end

    # sorts an image
    def self.sort_image path
      type = rand(0..3)
      diagonal = [true,false].sample
      case type
        when 0
          puts 'Generating brute sort...'
          Pxlsrt::Brute.brute(path, diagonal: diagonal, middle: rb, vertical: rb).save(path)
        when 1
          puts 'Generating smart sort...'
          Pxlsrt::Smart.smart(path, threshold: rand(100..200), diagonal: diagonal).save(path)
        when 2
          puts 'Generating kim sort...'
          Pxlsrt::Kim.kim(path).save(path)
        when 3
          puts 'Generating seed sort...'
          Pxlsrt::Seed.seed(path, threshold: rand(0.1..10), distance: rand(20..50)).save(path)
      end
      puts 'Pixel sort successful, uploading...'
      return path
    end

    # classes

  end
end
