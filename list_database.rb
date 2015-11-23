require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
require 'colorize'

#tumbot.reblog_random_text_post
puts 'Doomybot started!'

Ask.all.each do |ask|
	puts "#{ask.id}: #{ask.text}".blue if ask.id % 2 == 0
	puts "#{ask.id}: #{ask.text}".yellow if ask.id % 2 == 1
end
