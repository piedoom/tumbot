require 'nokogiri'
#not an activerecord object!  Just a regular old object.

class TextPost
	attr_accessor :id, :reblog_key, :user, :body, :content
	def initialize post
		@id = post['posts'][0]['id'] 
		@reblog_key = post['posts'][0]['reblog_key']
		@user = post['blog_name']
		@body = post['posts'][0]['body']
		
		doc = Nokogiri::HTML(@body)
		doc.search('a').each do |a|
			a.parent.remove
		end
		doc.search('img').each do |img|
			Image.create(url: img['src'])
			img.parent.remove
		end
		values = (doc.css("p"))

		#stuff we can add to the database
		@content = values.to_a
	end
end
