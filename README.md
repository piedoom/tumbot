# tumbot
The learning Tumblr Bot that answers your questions!

##Example
[Tumbot is running here, as doomybot.](http://bot.doomy.me/)
**Warning:** Blog contains NSFW text (due to the internet doing what the internet does best - teaching AI only about adult topics)

##Setup
Setup is simple - we will be using bundle and rake.

`bundle install`

and then

`rake migrate`

Config of the bot is a little ugly right now.
Modify the constants in lib/doomybot.rb



##Running

To run the bot, enter the following from the root folder

```bash
bin/app
```

To experiment with the bot, run the following from the root folder

```bash
bin/console
```

You will then have access to all of the methods on demand.