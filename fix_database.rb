require_relative 'initialize.rb'
require_relative 'tumbot/client.rb'
tumbot = Tumbot::Client.new

# this will fix the problem doomybot had when inserting punctuation
# it would result in asks looking like this:
# Hello!.
# Space before period .
puts 'fixing database...'

changes = 0
deleted = 0

Ask.all.each do |ask|
	start = ask.text
	if ask.text
		puts "#{ask.text}".red
		ask.text = ask.text.gsub(/\s+/,' ')
		ask.text[0] = '' if ask.text[0] == ' '
		ask.text[-2..-1] = '.' if ask.text[-2..-1] =~ /\ \./ and ask.text[-3..-3] !~ /\./
		ask.text[-2..-1] = '' if ask.text[-3..-3] =~ /(\.|\?|\!)/
		ask.text[-1..-1] = '' if ask.text[-2..-2] =~ /(\.|\?|\!)/
		if ask.text.gsub(/[^0-9A-Za-z]/,'').length > 3
			puts "#{ask.text}".yellow
		else 
			puts "[DELETED]".yellow
			ask.destroy
			deleted = deleted + 1
		end
		ask.save!
		changes = changes + 1 if start != ask.text
	end
	puts 
	puts 
end
puts "#{deleted} items deleted.".red
puts "#{changes} changes made.".green
