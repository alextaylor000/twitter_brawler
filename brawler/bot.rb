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

		# ignore tweets before and including this ID
		#since_id 596544746069368832

		debug "init listen"

		loop do
			begin
				# https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline
				# Rate: 15 requests / 15 minutes
				num_replies = 0

				replies do |tweet|
					# tweet.in_reply_to_screen_name = "twtfu"
					# tweet.text = full text of the tweet, i.e. "@twtfu test tweet"
					# tweet.user.screen_name = the sender of the tweet, i.e. "twtfu_test0001"
					# tweet.user_mentions = array of mentions, i.e. each user mentioned in the tweet
						# tweet.user_mentions.first.screen_name = "twtfu", for example

					debug "#{tweet.text}"
					num_replies += 1
					process tweet
					
				end
				debug "processed #{num_replies} replies"

				# update chatterbot config. this is apparently required
				update_config

				sleep 60

			rescue Twitter::Error::TooManyRequests => error
				sleep_seconds = error.rate_limit.reset_in + 10
				debug "~~ RATE LIMITED, sleeping for #{sleep_seconds} ~~"
				sleep sleep_seconds
			end # begin/rescue

		# send tweets every loop
		# TODO: this will be rate-limited by the replies block above. is this a problem?
		debug "running send_tweets"
		send_tweets

		end # loop
	
	end # listen


	# Forks a new thread to execute the action
	def process (tweet)
		to = tweet.user_mentions.last.screen_name # for now, assume the last mention is the correct person
		from = tweet.user.screen_name
		text = tweet.text

  		# spawn a new thread so that the action can wait a set amount of time for a block move without...well, blocking.
  		Thread.new {
  			debug "init action #{from}, #{text}, #{to}"
	  		action = Action.new from, text, to, tweet

	  		if action.fight
		  		action.execute
		  	end
	  	}

	end

	# Send a tweet on behalf of the bot.
	def send_tweets
		
		tweets = TweetQueue.all
		
		tweets.each do |tweet|
			
			text 			= tweet.text
			
			tweet_source 	= {:id => tweet.source}
			
			debug "sending tweet: #{text}"
			
			reply text, tweet_source
			tweet.destroy

		end # tweets.each

	end # send_tweets
end # class TwitterBot

# runtime

# reset db for testing
Fight.destroy_all
Fighter.destroy_all	
TweetQueue.destroy_all


bot = TwitterBot.new
debug "loading bot.listen..."
bot.listen


