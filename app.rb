require_relative 'initialize.rb'
tumbot = Tumbot::Bot.new

while true
	#Thread.new do
		tumbot.check
		#tumbot.index
		sleep 6
	#end
end


