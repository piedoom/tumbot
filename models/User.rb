class User < ActiveRecord::Base
	has_many :asks
end
