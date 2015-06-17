# bot.rb
# The Twitter bot responsible for receiving and sending tweets. Powered by chatterbot.

#require 'chatterbot/dsl'

# TODO: make these environment variables
require 'byebug'
require 'chatterbot/dsl'
require 'daemons'

require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# action.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

Thread.abort_on_exception=true

DaemonOptions = {
	:ontop => true,
	:backtrace => true,
	:log_output => true,
	:dir => "logs",
	:app_name => "#{__FILE__}"
}




class Twitter::Tweet
	# Queries our TweetID model to determine if the tweet ID is already in there.
	def is_unique?
		this_id = TweetID.all(:tweet_id => self.id)
		this_id.empty?
	end
end

class TwitterBot
	def initialize
		consumer_key ENV['TWTFU_CONSUMER_KEY']
		consumer_secret ENV['TWTFU_CONSUMER_SECRET']

		token ENV['TWTFU_TOKEN']
		secret ENV['TWTFU_SECRET']
	end

	# Listen for tweets @twtfu
	def listen
		# ignore tweets before and including this ID
		#since_id 596544746069368832
		
		debug "TwitterBot is listening ..."

		Thread.new {
			debug "Init pending_move thread"

			loop do
				process_pending_moves
				sleep 5
			end
		}

		
		streaming do
			begin
				replies do |tweet|
					# Find any fights with pending moves and execute them if the block grace period has expired

					# tweet.in_reply_to_screen_name = "twtfu"
					# tweet.text = full text of the tweet, i.e. "@twtfu test tweet"
					# tweet.user.screen_name = the sender of the tweet, i.e. "twtfu_test0001"
					# tweet.user_mentions = array of mentions, i.e. each user mentioned in the tweet
						# tweet.user_mentions.first.screen_name = "twtfu", for example					
					debug "Incoming Tweet: '#{tweet.text}' <id #{tweet.id}, time: #{tweet.created_at}>"
					process tweet
					TwitterBot.send_tweets
					
				end
			rescue Twitter::Error => error
				debug "Twitter error: #{error.message}"
			end




			# METHODS
			# These are in here for a good reason: right now we're in StreamingHandler's scope.
			# So method calls to these methods will not work unless they're included within
			# this scope, or made public. This was the quickest way ;)

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

				# help!
				if text.include? "help"
					tweet = TweetQueue.create(:text => "@#{from}: welcome to the dojo. Find the answers you seek at http://twtfu.tumblr.com #{TwitterBot.random_chars(1)}", :source => tweet.id)
					tweet.save
					return
				end

				debug "New Action: [from: #{from}, text: #{text}, to: #{to}]"
		  		action = Action.new from, text, to, time, tweet.id

		  		if action.fight
		  			debug "Executing action #{action.id}..."
			  		action.execute
			  	else
			  		debug "ERROR: Fight not found. Action #{action.id} will not execute"
			  	end


			end






		end # streaming
	end # listen

	# Process pending moves for fights which have them.
	def process_pending_moves
		fights_with_pending_moves = Fight.where(:pending_move => {  :$exists => true, :$ne => {}  }) 
		
		fights_with_pending_moves.each do |fight|
			pending_move = fight.pending_move
			
			if Time.now - pending_move[:created_at] > ActionGracePeriodSeconds + 2
				# padding the grace period so that it's guaranteed any block move
				# has had a chance to be processed (since this method will be running
				# in another thread, we don't want any race conditions)
				action = Action.new pending_move[:from], "text", pending_move[:to], pending_move[:created_at], pending_move[:tweet_id], pending_move[:type]
				
				if action.fight
					debug "Fight: #{fight.title}: Executing pending move after grace period #{ActionGracePeriodSeconds} expired"
					action.execute_pending_move
					TwitterBot.send_tweets
				end
				
			end
		end
	end

	# Send a tweet on behalf of the bot.
	def TwitterBot.send_tweets
		consumer_key ENV['TWTFU_CONSUMER_KEY']
		consumer_secret ENV['TWTFU_CONSUMER_SECRET']

		token ENV['TWTFU_TOKEN']
		secret ENV['TWTFU_SECRET']

		tweets = TweetQueue.all
		
		tweets.each do |tweet|
			
			text 			= tweet.text
			
			tweet_source 	= {:id => tweet.source}
			
			begin
				new_tweet = reply(text, tweet_source)
			rescue Twitter::Error => error
				debug "*** ERROR SENDING TWEET: #{error}"
			end
			
			unless new_tweet.is_unique?
				random_suffix = self.random_chars(2)

				# TODO: refactor (redundant)
				begin
					new_tweet = reply(text + random_suffix, tweet_source)
					debug "Duplicate tweet id detected; adding random emoji"
				rescue Twitter::Error => error
					debug "*** ERROR SENDING TWEET: #{error}"
				end
			end
			

			t_id = TweetID.create(:tweet_id => new_tweet.id)
			t_id.save


			tweet.destroy
			debug "Outgoing Tweet: #{new_tweet.text}"

		end # tweets.each

	end # send_tweets	

	# Returns random characters to append to message
	def TwitterBot.random_chars(num)
		chars = ["\u270a","\u231b","\u23f3","\u26a1","\u2b50","\u1f4aa"]
		return chars[rand(chars.count)]
	end


end # class TwitterBot

# runtime

# reset db for testing
#Fight.destroy_all
#Fighter.destroy_all	
#TweetQueue.destroy_all
puts "Daemonizing..."
Daemons.daemonize(DaemonOptions)
bot = TwitterBot.new
bot.listen


