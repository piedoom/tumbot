# tumbot
The learning Tumblr Bot that answers your questions!

##Setup
Setup is simple - we will be using bundle and rake.

`bundle install`

and then

`rake migrate`

You will need to manually adjust environment variables to suit your case.  They are currently:

`'TUMBLR_CONSUMER_KEY'`

`'TUMBLR_CONSUMER_SECRET'`

`'TUMBLR_OAUTH_TOKEN'`

`'TUMBLR_OAUTH_TOKEN_SECRET'`

and

`'TUMBLR_BOT_BLOG_NAME'` which is the name of the blog you are posting to, for example "bot.tumblr.com"


##Running

simply run with `ruby app.rb`
