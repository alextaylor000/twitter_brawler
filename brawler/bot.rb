# bot.rb
# The Twitter bot responsible for receiving and sending tweets. Powered by chatterbot.

#require 'chatterbot/dsl'

# TODO: make these environment variables
require 'byebug'
require 'chatterbot/dsl'

require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# action.rb

class TwitterBot

	# Listen for tweets @twtfu
	def listen
		consumer_key 'e6IZLNgC4tFd7EzMOW0PepruG'
		consumer_secret 'tI4UQog02tRsDMgDuJP9X2ZE9DoJM2K5rEGbXSaWPDN8qw9gT2'
		secret 'LKuuyh7smscGxp550KnEaFvMUCqFnwCdhDQJNhTFUWxjp' 
		token '3228612387-xeQ9dwHVZIZaYYopbyPRzI6SyjVNFTQRW6VinsM'

		streaming replies:"all" do

			replies do |tweet|
				# tweet.in_reply_to_screen_name = "twtfu"
				# tweet.text = full text of the tweet, i.e. "@twtfu test tweet"
				# tweet.user.screen_name = the sender of the tweet, i.e. "twtfu_test0001"
				# tweet.user_mentions = array of mentions, i.e. each user mentioned in the tweet
					# tweet.user_mentions.first.screen_name = "twtfu", for example
				#process tweet

				debug ">> #{tweet.text}"
				byebug
			end

		end		
	end

	# Forks a new thread to execute the action
	def process (tweet)
		tweet.user_mentions.each do |mention|

		end

		from = tweet.user.screen_name
		text = tweet.text

  		# spawn a new thread so that the action can wait a set amount of time for a block move without...well, blocking.
  		Thread.new {
	  		action = Action.new input

	  		if action.fight
		  		result = action.execute
		  		puts result
		  	end
	  	}

	end

	# Send a tweet on behalf of the bot.
	def send (text)
	end
end

# runtime
bot = TwitterBot.new
bot.listen

