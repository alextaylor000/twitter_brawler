# action.rb
# An Action is created by a tweet; it controls the interaction between the user and the models

require 'timeout' # required to process pending moves
require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/moves') 	# moves.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

ActionGracePeriodSeconds = 10	# wait this many seconds for a block before executing a move

# TestTweet provides a fake id to pass into the store_tweet method for debugging purposes
class TestTweet
	def initialize(id)
		@id = id
	end

	def id
		return @id
	end
end

class Action
	include Moves

	# Initialize an action; get all relevant objects and retrieve the action type from the string
	# from: the user who sent the tweet
	# text: the full text of the tweet, for parsing
	# to: who the user tweeted at - their challenger
	def initialize(from, text, to, tweet=nil)
		inputs 	= text.split " "
		@tweet 	= tweet # store the original tweet object to pass into the TweetQueue model

		if tweet == nil
			@tweet = TestTweet.new(1) # for console testing
		end

		@from 	= get_fighter from		# assign a fighter object or create one
		@type 	= nil # stub for grabbing the type in the block below

		inputs.each do |i|
			next if i.include? "@"
			@type = i.downcase 	# assign the type as the first keyword that's not a mention
			break 				# stop analyzing after the first keyword (to allow random characters at the end of the tweet)
		end

		@to   	= get_fighter to	# assign a fighter object or create one


		@title  = get_title					# get the fight id for looking up fights; created from a hash of both users, sorted 		
		@fight 	= get_fight					# assign a fight object or create one
		
		debug "init action {from: #{@from.user_name}, type:#{@type}, to: #{@to.user_name}"
	end

	# Execute the current action. Return the result, and check for win conditions.
	def execute
		debug "execute action #{@type.to_sym}"

		result = []

		# Execute the move only if the user who requested it has initiative.

		# If there's no pending move in the fight (e.g. the first move in the fight), store
		# the move in @fight.pending_move so that the receiving user has a chance to respond

		# When the other user responds, the pending move will either be turned into a block,
		# or it will be executed before the receiving user's attack

		debug "save log for #{@from}, #{@type}, #{@to}"
		save_log # add it to the fight log
		# TODO: we'll probably eventually want to filter this log a little more and record just the real moves

		if @fight.initiative == @from.user_name
			
			if @fight.pending_move.empty?

				if @type == "block"
					result << "No move to block!" # TODO: when would this get triggered? I forget...

				elsif @type == "challenge" or @type == "accept"
					result << self.__send__(@type.to_sym, @fight, @from, @to)

				else
					# add the current move to fight.pending_move
					debug "set pending move"
					set_pending_move

					# pass the initiative to the other player before waiting for a block					
					@fight.initiative = @to.user_name # initiative goes to other player after a successful move
					@fight.save

					# process the move; wait to see if a block is received
					result << process_move
				end

			else # a pending action is present
				if @type == "block"
					result << self.__send__(@type.to_sym, @fight, @from, @to) # execute block move (block will be aware of the pending move)

					reset_pending_move
				else
					pending_move_type 	= @fight.pending_move[:type]
					pending_move_from 	= Fighter.where(:user_name => @fight.pending_move[:from] ).first
					pending_move_to 	= Fighter.where(:user_name => @fight.pending_move[:to] ).first

					result << self.__send__(pending_move_type.to_sym, @fight, pending_move_from, pending_move_to) # execute the pending move
					
					# store the current move as the new pending move
					result << set_pending_move					
				end				
			end

			if result.any?
				debug "initiative #{@to.user_name}"
				@fight.initiative = @to.user_name # initiative goes to other player after a successful move
				@fight.save
				
			end

		else
			# If the requesting user doesn't have initiative
			#result << "It's not your turn!"
			
			debug "Not your turn"
		end

		

		if result.any?
			result.last.replace (result.last + " @#{@fight.initiative}'s move") unless result.empty?
		end
		
		

		# check players' hp for death condition
		if @fight.status == "active"
			winner = check_for_winner
			if winner
				result << "#{winner.user_name} wins! +XP"
				@fight.status = "won"
				@fight.save
			end
		end

		#return result
		debug "storing tweet(s) #{result}"
		store_tweets result

	end

	# Return the winner of the fight, or false if win condition not yet met
	def check_for_winner
	
		if @from.fights_hp[@title] <= 0 
			return @to
		elsif @to.fights_hp[@title] <= 0
			return @from
		else
			return false
		end
	end

	# Return the fight object
	def fight
		@fight
	end

	# Update the fight log; this stores each move in the fight
	def save_log
		@fight.fight_actions << FightAction.new(:from => @from.user_name, :move => @type, :to => @to.user_name)
		@fight.save!
		debug "save_log last move: #{@fight.fight_actions.last.move}"
	end

	# Waits for a 'block' move, otherwise executes the move
	def process_move
		blocked = false

		begin
			debug "processing move, waiting for block..."
			status = Timeout::timeout(ActionGracePeriodSeconds) {
			  while true do 
			  	@fight.reload
			  	# check for a 'block' move being inserted into the database
			  	debug "last move: #{@fight.fight_actions.last.move}"
			  	blocked = true if @fight.fight_actions.last.move == "block"
			  	sleep 1
			  end
			}

		rescue Timeout::Error
			# intentional stub; we're really looking to pass through to ensure
		ensure
			if blocked
				# nothing should happen here because the block will be processed by the block's action thread				
			else
				debug "not blocked! processing action"
				reset_pending_move 
				return self.__send__(@type.to_sym, @fight, @from, @to) # execute a move - it will either be 'block' or the original move type
			end
			
			

		end
	end

	def set_pending_move
		@fight.pending_move = {:type => @type, :from => @from.user_name, :to => @to.user_name}
		@fight.save		
		return "#{@from.user_name} attacks #{@to.user_name} with #{@type}. block or attack?"
	end

	def reset_pending_move
		@fight.pending_move = {}
		@fight.save
	end

	# Returns a Fighter object from the database based on the username
	def get_fighter(name)
		fighter = Fighter.where(:user_name => name).first

		if fighter.nil?
			fighter = Fighter.create(:user_name => name, :xp_points => 0)
			fighter.save
		end

		return fighter
	end

	# Generate a Fight title; the fight title is how an existing fight is retrieved from action to action. Formatted like "username_vs_username"
	def get_title
		# TODO: move this into the Fight class; could probably be created automatically
		return [@from.user_name, @to.user_name].sort.join "_vs_"
	end

	# Returns a fight object or creates one if it doesn't exist.
	def get_fight
		fight = Fight.where(:title => @title, :status => {:$nin => ["won"]}).first
		
		if fight.nil? \
			or fight.status == "won"

			if @type == "challenge"
				fight = Fight.new(:title => @title, \
									:status => "inactive", \
									:challenger => @from.user_name, \
									:challenged => @to.user_name, \
									:initiative => @from.user_name) 
				fight.save

				debug "new fight created: #{@title} <#{fight.id}>"
			else
				fight = false
				debug "invalid command, need to issue 'challenge' first"
			end

			
					
		else
			debug "using existing fight #{@title} <#{fight.id}>"
		end

		return fight
	end

	# Stores a tweet in the TweetQueue model so that the bot can access it
	def store_tweets (tweets)

		tweets.each do |t|
			new_tweet = TweetQueue.create(:text => t, :source => @tweet.id)
			new_tweet.save

			debug "saved tweet to db"
		end

	
	end

end