require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
require 'colorize'

#tumbot.reblog_random_text_post
puts 'Doomybot started!'

Ask.all.each do |ask|
	puts "#{ask.id}: #{ask.text}".blue if ask.id % 2 == 0
	puts "#{ask.id}: #{ask.text}".yellow if ask.id % 2 == 1
end

while true
puts "Enter id of item to delete: ".chomp.red

var = gets.chomp

ask = Ask.find(var.to_i)

puts "Are you sure you want to delete this ask? (press any key to continue) \n#{ask.text}"

gets

ask.destroy
end
