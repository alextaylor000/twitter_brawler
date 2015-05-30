# action.rb
# An Action is created by a tweet; it controls the interaction between the user and the models

require 'timeout' 		# to process pending moves
require 'securerandom' 	# to genereate a random string to append to title after winning
require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/moves') 	# moves.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

ActionGracePeriodSeconds = 30	# wait this many seconds for a block before executing a move

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
	#include Moves

	# Initialize an action; get all relevant objects and retrieve the action type from the string
	# from: the user who sent the tweet
	# text: the full text of the tweet, for parsing
	# to: who the user tweeted at - their challenger
	def initialize(from, text, to, time, tweet_id=nil, type=nil)
		return false if text.strip.empty?
		@id = SecureRandom.hex # unique id for this action

		@tweet_id 	= tweet_id # store the original tweet object to pass into the TweetQueue model


		@created_at = time
		@from 	= get_fighter from		# assign a fighter object or create one
		@type 	= type.to_s 			# use type from init argument or nil (and created it below)

		
		if @type.empty?
			keywords = []

			# remove mentions
			inputs 	= text.split " "
			inputs.each do |i|
				next if i.include? "@"
				keywords << i
			end

			# check for two keywords
			if Moves::AttackPoints.keys.include? [keywords[0], keywords[1]].join("_").to_sym
				@type = [keywords[0], keywords[1]].join("_")
			
			# check for one keywords
			elsif Moves::AttackPoints.keys.include? keywords[0].to_sym
				@type = keywords[0]
			else
				debug "Action #{@id}: '#{keywords}' does not contain a valid move."
				return false
			end
		end

		debug "Action #{@id}: Found move type '#{@type}'"

		@to   	= get_fighter to	# assign a fighter object or create one


		@title  = get_title					# get the fight id for looking up fights; created from a hash of both users, sorted 		
		@fight 	= get_fight					# assign a fight object or create one

		return false if @fight == false

		
		debug "Action #{@id}: Init complete [from: #{@from}, to: #{@to}, fight: #{@fight.title}, type: #{@type}]"

	end

	# Execute the current action. Return the result, and check for win conditions.
	def execute
		#debug "execute action #{@type.to_sym}"

		result = []

		# Execute the move only if the user who requested it has initiative.

		# If there's no pending move in the fight (e.g. the first move in the fight), store
		# the move in @fight.pending_move so that the receiving user has a chance to respond

		# When the other user responds, the pending move will either be turned into a block,
		# or it will be executed before the receiving user's attack

		#debug "save log for #{@from}, #{@type}, #{@to}"
		save_log # add it to the fight log
		# TODO: we'll probably eventually want to filter this log a little more and record just the real moves
		
		if @fight.initiative == @from.user_name
			
			if @fight.pending_move.empty?

				if @type == "block"
					debug "Action #{@id}: Pending move is empty, can't execute block."
					invalid_move

				elsif @type == "challenge" or @type == "accept"
					result << Moves.__send__(@type.to_sym, @fight, @from, @to)

				else
					# only process a move if it's valid
					if Moves.methods.include? @type.to_sym and fight_is_active

						# add the current move to fight.pending_move
						set_pending_move

						# pass the initiative to the other player before waiting for a block					
						@fight.initiative = @to.user_name # initiative goes to other player after a successful move
						@fight.save

						debug "Action #{@id}: Move stored in pending_move"
						# # process the move; wait to see if a block is received
						# tweet = process_move
						# result << tweet unless tweet == nil

					else
						invalid_move
					end
				end

			else # a pending action is present
				if @type == "block"
					debug "Action #{@id}: Received block move"

					if @created_at - @fight.pending_move[:created_at] <= ActionGracePeriodSeconds
						result << Moves.__send__(@type.to_sym, @fight, @from, @to) # execute block move (block will be aware of the pending move)
						reset_pending_move
					else
						debug "Action #{@id}: Block was too slow. Not executing."
					end					
					
				else
					# only process a move if it's valid
					if Moves.methods.include? @type.to_sym and fight_is_active
						result << execute_pending_move
						reset_pending_move

						# store the current move as the new pending move
						#result << set_pending_move
						result << Moves.__send__(@type.to_sym, @fight, @from, @to)
					end			
				end				
			end

			if result.any?
				@fight.initiative = @to.user_name # initiative goes to other player after a successful move
				@fight.save
				
			end

		else
			# If the requesting user doesn't have initiative			
			debug "Action #{@id}: Action ignored, move by #{@from.user_name} but #{@to.user_name} has initiative"
		end


		process_results(result)


	end


	# Return the winner of the fight, or false if win condition not yet met
	def check_for_winner
		@from.reload
		@to.reload

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

	def id
		@id
	end

	def fight_is_active
		if @fight.status == "active"
			return true
		else
			return false
		end
	end


	# Runs when an invalid move is passed in
	def invalid_move
		debug "Action #{@id}: Invalid move"
	end

	# Update the fight log; this stores each move in the fight
	def save_log
		@fight.fight_actions << FightAction.new(:from => @from.user_name, :move => @type, :to => @to.user_name)
		@fight.save!
		#debug "save_log last move: #{@fight.fight_actions.last.move}"
	end

	# Waits for a move by the other player, otherwise executes the move
	def process_move
		block_successful = false
		
		begin
			debug "Action #{@id}: Processing #{@type}, listening for block (#{ActionGracePeriodSeconds}s)..."

			status = Timeout::timeout(ActionGracePeriodSeconds) {
			  while true do 
			  	@fight.reload # reload the instance variable from the database to ensure we catch any changes to fight_actions
			  	
			  	# check for a move by the other user
			  	block_successful = true if @fight.fight_actions.last.from == @to.user_name
			  	sleep 1
			  end
			}

			debug "Action #{@id}: Finished waiting for block."

		rescue Timeout::Error
			# intentional stub; we're really looking to pass through to ensure
			debug "Action #{@id}: Timeout. Block successful: #{block_successful}"

		ensure
			unless block_successful
				reset_pending_move
				return Moves.__send__(@type.to_sym, @fight, @from, @to) # execute a move
			end			

		end
	end

	def process_results(result)
		# append initiative to last tweet
		if result.any?
			result.last.replace (result.last + " @#{@fight.initiative}'s move") unless result.empty?
		end

		# check players' hp for death condition
		if @fight.status == "active"
			byebug
			winner = check_for_winner
			if winner
				result << Moves.__send__(:win, @fight, @from, @to, winner.user_name)
				reset_pending_move # just in cases
				@fight.status = "won"
				@fight.title = @title + "_" + SecureRandom.hex
				@fight.save
			end
		end

		if result.any?
			debug "Action #{@id}: Storing tweets: #{result}"
			store_tweets result
		end
	
	end


	def set_pending_move
		debug "Action #{@id} saving pending move #{@type}"
		@fight.pending_move = {:type => @type, :from => @from.user_name, :to => @to.user_name, :created_at => @created_at, :tweet_id => @tweet_id}
		@fight.save		
	end

	def execute_pending_move
		pending_move_type 	= @fight.pending_move[:type]
		pending_move_from 	= Fighter.where(:user_name => @fight.pending_move[:from] ).first
		pending_move_to 	= Fighter.where(:user_name => @fight.pending_move[:to] ).first

		result = []
		result << Moves.__send__(pending_move_type.to_sym, @fight, pending_move_from, pending_move_to) # execute the pending move

		process_results result

		reset_pending_move

	end

	def reset_pending_move
		@fight.pending_move = nil
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

				#debug "new fight created: #{@title} <#{fight.id}>"
			else

				fight = false
				#debug "invalid command, need to issue 'challenge' first"
			end

			
					
		else
			#debug "using existing fight #{@title} <#{fight.id}>"
		end


		return fight
	end

	# Stores a tweet in the TweetQueue model so that the bot can access it
	def store_tweets (tweets)
		tweets.each do |t|
			new_tweet = TweetQueue.create(:text => t, :source => @tweet_id)
			new_tweet.save

		end
	
	end

end