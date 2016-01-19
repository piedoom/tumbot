#not an activerecord object!  Just a regular old object.

class TextPost
	attr_accessor :id, :reblog_key, :user, :body, :content

	def initialize post
		@id = post['posts'][0]['id'] 
		@reblog_key = post['posts'][0]['reblog_key']
		@user = post['blog_name']
		@body = post['posts'][0]['body']

		# remove links
		doc = Nokogiri::HTML(@body)
		doc.search('a').each do |a|
			a.parent.remove
		end
		# add images to our database
		doc.search('img').each do |img|
			Image.create(url: img['src'])
			img.parent.remove
		end
		# sanitize our html so each user has but one post
		doc = doc.xpath("//text()").to_s.gsub(":",'')
		doc = doc.split(/\n+/)
		@content = doc
	end
end
