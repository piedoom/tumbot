require_relative 'initialize.rb'
tumbot = AsksController.new

while true
	Thread.new do
		tumbot.check
		#tumbot.index
		sleep 6
	end
end


