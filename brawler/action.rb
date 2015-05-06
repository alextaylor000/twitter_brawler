# action.rb
# An Action is created by a tweet; it controls the interaction between the user and the models

require File.expand_path(File.dirname(__FILE__) + '/moves') 	# moves.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb


class Action
	include Moves

	# Initialize an action; get all relevant objects and retrieve the action type from the string
	def initialize(input)
		inputs 	= input.split " "

		@from 	= get_fighter inputs[0]		# assign a fighter object or create one
		@type 	= inputs[1...-1].join("_")
		@to   	= get_fighter inputs[-1]	# assign a fighter object or create one

		@title  = get_title			# get the fight id for looking up fights; created from a hash of both users, sorted 		
		@fight 	= get_fight					# assign a fight object or create one
		

		debug "init action {from: #{@from.user_name}, type:#{@type}, to: #{@to.user_name}"
	end

	# Execute the current action. Return the result, and check for win conditions.
	def execute
		
		debug "execute action #{@type.to_sym}"

		if @fight.initiative == @from.user_name
			result = self.__send__(@type.to_sym, @fight, @from, @to) # execute the Move

			if result
				@fight.initiative = @to.user_name # initiative goes to other player after a successful move
				save_log # add it to the fight log
			end

		else
			result = "It's not your turn!"
		end

		result = "Invalid move #{@type}" if result == false

		# check players' hp for death condition
		if @fight.status == "active"
			winner = check_for_winner
			if winner
				result = [result, "#{winner.user_name} wins! +XP"]
				@fight.status = "won"
				@fight.save
			end
		end

		return result

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

	# Update the fight log; this stores each move in the fight
	def save_log
		@fight.fight_actions << FightAction.new(:from => @from.user_name, :move => @type, :to => @to.user_name)
		@fight.save!
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
			fight = Fight.new(:title => @title, \
								:status => "inactive", \
								:challenger => @from.user_name, \
								:challenged => @to.user_name, \
								:initiative => @from.user_name) 
			fight.save

			debug "new fight created: #{@title} <#{fight.id}>"
					
		else
			debug "using existing fight #{@title} <#{fight.id}>"
		end

		return fight
	end

end