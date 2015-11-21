require 'sanitize'
#not an activerecord object!  Just a regular old object.
class TextPost
	attr_accessor :id, :reblog_key, :user, :body
	def initialize post
		@id = post['posts'][0]['id'] 
		@reblog_key = post['posts'][0]['reblog_key']
		@user = post['blog_name']
		@body = Sanitize.fragment(post['posts'][0]['body'])
	end
end
