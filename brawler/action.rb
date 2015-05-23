# action.rb
# An Action is created by a tweet; it controls the interaction between the user and the models

require 'timeout' # required to process pending moves
require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/moves') 	# moves.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

ActionGracePeriodSeconds = 2	# wait this many seconds for a block before executing a move

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
		return false if text.strip.empty?

		inputs 	= text.split " "
		@tweet 	= tweet # store the original tweet object to pass into the TweetQueue model

		if tweet == nil
			@tweet = TestTweet.new(1) # for console testing
		end

		@from 	= get_fighter from		# assign a fighter object or create one
		@type 	= nil # stub for grabbing the type in the block below

		keywords = []

		# remove mentions
		inputs.each do |i|
			next if i.include? "@"
			keywords << i
		end



		# check for two keywords
		if Moves::AttackPoints.keys.include? [keywords[0], keywords[1]].join("_").to_sym
			debug "is #{[keywords[0], keywords[1]].join("_")} a valid move?"
			@type = [keywords[0], keywords[1]].join("_")
		
		# check for one keywords
		elsif Moves::AttackPoints.keys.include? keywords[0].to_sym
			debug "is #{keywords[0]} a valid move?"
			@type = keywords[0]
		else
			debug "#{keywords} does not contain a valid move"
			return false
		end

		debug "type: #{@type}"

		@to   	= get_fighter to	# assign a fighter object or create one


		@title  = get_title					# get the fight id for looking up fights; created from a hash of both users, sorted 		
		@fight 	= get_fight					# assign a fight object or create one
		
		#debug "init action {from: #{@from.user_name}, type:#{@type}, to: #{@to.user_name}"
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
					invalid_move

				elsif @type == "challenge" or @type == "accept"
					result << self.__send__(@type.to_sym, @fight, @from, @to)

				else
					# only process a move if it's valid
					if Moves.instance_methods.include? @type.to_sym and fight_is_active

						# add the current move to fight.pending_move
						set_pending_move

						# pass the initiative to the other player before waiting for a block					
						@fight.initiative = @to.user_name # initiative goes to other player after a successful move
						@fight.save

						# process the move; wait to see if a block is received
						result << process_move

					else
						invalid_move
					end
				end

			else # a pending action is present
				if @type == "block"
					result << self.__send__(@type.to_sym, @fight, @from, @to) # execute block move (block will be aware of the pending move)

					reset_pending_move
				else
					# only process a move if it's valid
					if Moves.instance_methods.include? @type.to_sym and fight_is_active
						pending_move_type 	= @fight.pending_move[:type]
						pending_move_from 	= Fighter.where(:user_name => @fight.pending_move[:from] ).first
						pending_move_to 	= Fighter.where(:user_name => @fight.pending_move[:to] ).first

						result << self.__send__(pending_move_type.to_sym, @fight, pending_move_from, pending_move_to) # execute the pending move
						reset_pending_move

						# store the current move as the new pending move
						#result << set_pending_move
						result << self.__send__(@type.to_sym, @fight, @from, @to)
					end			
				end				
			end

			if result.any?
				@fight.initiative = @to.user_name # initiative goes to other player after a successful move
				@fight.save
				
			end

		else
			# If the requesting user doesn't have initiative
			#result << "It's not your turn!"
			
			#debug "Not your turn"
		end

		debug "result: #{result}"

		# append initiative to last tweet
		if result.any?
			result.last.replace (result.last + " @#{@fight.initiative}'s move") unless result.empty?
		end

		
		

		# check players' hp for death condition
		if @fight.status == "active"
			winner = check_for_winner
			if winner
				result << self.__send__(:win, @fight, @from, @to, winner.user_name)
				@fight.status = "won"
				@fight.save
			end
		end

		#return result
		#debug "storing tweet(s) #{result}"
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

	def fight_is_active

		if @fight.status == "active"
			return true
		else
			return false
		end
	end


	# Runs when an invalid move is passed in
	def invalid_move
		debug "invalid move"
	end

	# Update the fight log; this stores each move in the fight
	def save_log
		@fight.fight_actions << FightAction.new(:from => @from.user_name, :move => @type, :to => @to.user_name)
		@fight.save!
		#debug "save_log last move: #{@fight.fight_actions.last.move}"
	end

	# Waits for a move by the other player, otherwise executes the move
	def process_move
		execute_move = false

		begin
			debug "processing #{@type}, waiting for block (#{ActionGracePeriodSeconds}s)..."

			status = Timeout::timeout(ActionGracePeriodSeconds) {
			  while true do 
			  	@fight.reload # reload the instance variable from the database to ensure we catch any changes to fight_actions
			  	
			  	# check for a move by the other user
			  	execute_move = true if @fight.fight_actions.last.from != @from.user_name
			  	sleep 1
			  end
			}

		rescue Timeout::Error
			# intentional stub; we're really looking to pass through to ensure

		ensure
			unless execute_move
				reset_pending_move
				return self.__send__(@type.to_sym, @fight, @from, @to) # execute a move

			end			

		end
	end

	def set_pending_move
		@fight.pending_move = {:type => @type, :from => @from.user_name, :to => @to.user_name}
		@fight.save		
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
			new_tweet = TweetQueue.create(:text => t, :source => @tweet.id)
			new_tweet.save

		end
	
	end

end