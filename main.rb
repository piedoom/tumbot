require_relative 'initialize.rb'
require_relative 'manager.rb'

m = Manager.new

while true
	m.checkMessages
	sleep 6
end


