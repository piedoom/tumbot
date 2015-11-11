class UsersController
	#find or create a user
	def self.create username
		User.find_or_create_by(username: username)
	end
end
