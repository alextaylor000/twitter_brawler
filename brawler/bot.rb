# bot.rb
# The Twitter bot responsible for receiving and sending tweets. Powered by chatterbot.

#require 'chatterbot/dsl'

PollDurationInSeconds = 60

# TODO: make these environment variables
require 'byebug'
require 'chatterbot/dsl'

require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# action.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

class Twitter::Tweet
	# Queries our TweetID model to determine if the tweet ID is already in there.
	def is_unique?
		this_id = TweetID.all(:tweet_id => self.id)
		this_id.empty?
	end
end

class TwitterBot

	# Listen for tweets @twtfu
	def listen
		consumer_key 'e6IZLNgC4tFd7EzMOW0PepruG'
		consumer_secret 'tI4UQog02tRsDMgDuJP9X2ZE9DoJM2K5rEGbXSaWPDN8qw9gT2'
		secret 'LKuuyh7smscGxp550KnEaFvMUCqFnwCdhDQJNhTFUWxjp' 
		token '3228612387-xeQ9dwHVZIZaYYopbyPRzI6SyjVNFTQRW6VinsM'

		# ignore tweets before and including this ID
		#since_id 596544746069368832

		debug "TwitterBot is listening ..."
		debug "Poll duration: #{PollDurationInSeconds}s"

		loop do
			begin
				# https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline
				# Rate: 15 requests / 15 minutes
				debug "Polling for tweets ..."

				# Store tweets in an array so we can sort them according to timestamp
				replies_array = []

				begin
					replies do |tweet|
						replies_array << tweet
					end
				rescue Twitter::Error => error
					debug "Twitter error: #{error.message}"
				end

				# Find any fights with pending moves and execute them if the block grace period has expired

				# We're doing this before processing the tweets so that if a user tweets a move or block
				# outside of the grace period, but still within the same polling cycle, the pending move
				# will still have a chance to execute before anything else comes in.
				process_pending_moves


				replies_array.reverse!.each do |tweet|
					# tweet.in_reply_to_screen_name = "twtfu"
					# tweet.text = full text of the tweet, i.e. "@twtfu test tweet"
					# tweet.user.screen_name = the sender of the tweet, i.e. "twtfu_test0001"
					# tweet.user_mentions = array of mentions, i.e. each user mentioned in the tweet
						# tweet.user_mentions.first.screen_name = "twtfu", for example

					debug "Incoming Tweet: '#{tweet.text}' <id #{tweet.id}, time: #{tweet.created_at}>"
					process tweet
					
				end

				# update chatterbot config. this is apparently required
				update_config


				# send tweets every loop
				# TODO: this will be rate-limited by the replies block above. is this a problem?
				debug "send tweets temporarily disabled"
				#send_tweets

				sleep PollDurationInSeconds

			rescue Twitter::Error::TooManyRequests => error
				sleep_seconds = error.rate_limit.reset_in + 10
				debug "~~ RATE LIMITED, sleeping for #{sleep_seconds} ~~"
				sleep sleep_seconds
			end # begin/rescue

		end # loop
	
	end # listen


	# Forks a new thread to execute the action
	def process (tweet)
		to = nil

		tweet.user_mentions.each do |mention|
			sn = mention.screen_name

			unless sn == "twtfu"
				to = sn
				break
			end
		end

		from = tweet.user.screen_name
		text = tweet.text
		time = tweet.created_at


		debug "New Action: [from: #{from}, text: #{text}, to: #{to}]"
  		action = Action.new from, text, to, time, tweet.id

  		if action.fight
  			debug "Executing action #{action.id}..."
	  		action.execute
	  	else
	  		debug "ERROR: Fight not found. Action #{action.id} will not execute"
	  	end


	end

	# Process pending moves for fights which have them.
	def process_pending_moves
		fights_with_pending_moves = Fight.where(:pending_move => {  :$exists => true, :$ne => {}  }) 
		
		fights_with_pending_moves.each do |fight|
			pending_move = fight.pending_move
			
			if Time.now - pending_move[:created_at] > ActionGracePeriodSeconds
				debug "Fight: #{fight.title}: Executing pending move after grace period #{ActionGracePeriodSeconds} expired"
				action = Action.new pending_move[:from], "text", pending_move[:to], pending_move[:created_at], pending_move[:tweet_id], pending_move[:type]
				action.execute_pending_move
			end
		end
	end

	# Send a tweet on behalf of the bot.
	def send_tweets
		
		tweets = TweetQueue.all
		
		tweets.each do |tweet|
			
			text 			= tweet.text
			
			tweet_source 	= {:id => tweet.source}
			
			new_tweet = reply(text, tweet_source)
			
			unless new_tweet.is_unique?
				random_suffix = random_chars(2)
				new_tweet = reply(text + random_suffix, tweet_source)
				debug "Duplicate tweet id detected; adding random emoji"
			end
			
			store_id_of new_tweet

			tweet.destroy
			debug "Outgoing Tweet: #{new_tweet.text}"

		end # tweets.each

	end # send_tweets

	# Returns random characters to append to message
	def random_chars(num)
		chars = ["\u270a","\u231b","\u23f3","\u26a1","\u2b50"]
		return chars[rand(chars.count)]
	end

	# Stores the ID of the tweet in TweetID model
	def store_id_of(tweet)
		t_id = TweetID.create(:tweet_id => tweet.id)
		t_id.save
	end

end # class TwitterBot

# runtime

# reset db for testing
#Fight.destroy_all
#Fighter.destroy_all	
#TweetQueue.destroy_all


bot = TwitterBot.new
bot.listen


