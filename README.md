# tumbot
The learning Tumblr Bot that answers your questions!

##Setup
Setup is simple - we will be using bundle and rake.

`bundle install`

and then

`rake migrate`

Configuring the bot is easy enough - all files you need are included in the `config` directory.

`config.yml` specifies the bot's behavior

`credentials.yml` specifies the Tumblr API credentials

`database.yml` gives the settings for ActiveRecord.  They work as-is, but you can change them if you'd rather work with Postgres or MySQL.  

Both `config.yml` and `credentials.yml` allow for embedded ruby.


##Running

simply run with `ruby app.rb`
