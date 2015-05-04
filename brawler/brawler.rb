# brawler - a twitter fighting game
#
# the Listener object listens for input and passes it on to Receiver
# in order to process commands, Receiver should implement a function 
# for each command, with optional arguments
#
# an invalid method name passed to Receiver will trigger the method_missing
# method within Receiver

require 'digest'		# for generating fight IDs 
require 'mongo_mapper'	# for db hooks
require 'byebug' 		# for debugging

DEBUG = true

### CONSTANTS
TotalHitPoints = 25


def configure
	MongoMapper.database = "twtfudb"
end

def debug(msg)
	if DEBUG
		puts "* #{msg}"
	end
end

### MODELS AND MOVES
class Moves
	# moves should have three aguments: fight, from, to
	# they should return a result that can be tweeted
	# every move's logic should be passed as a block to if_is_active

	# default action for missing methods
	def method_missing(method_name, *args, &block)
		return false # let the controller handle notifying the user
	end

	# every normal move should be wrapped in this so that it only runs if the fight is active
	def if_is_active(fight)
		# TODO: is there a better way of accomplishing what I'm trying to do here?
		if fight.status == "active"
			yield
		else
			return false
		end
	end
	
	# challenge a player to a match
	def challenge(fight, from, to)
		if fight.status == "inactive"
			fight.status = "waiting"
			fight.save
			return "#{to.user_name}: #{from.user_name} has challenged you! accept?"
		end

	end

	# accept a fighter's challenge
	def accept(fight, from, to) 
		if fight.status == "waiting" \
			and from.user_name == fight.challenged

			fight.status = "active"
			fight.save

			# add hp to the fighters for this specific fight
			from.fights_hp[fight.title] 	= TotalHitPoints
			to.fights_hp[fight.title] 	= TotalHitPoints

			from.save
			to.save


			return "fight accepted. FIGHT!"

		end
	end


	def punch(fight, from, to)
		if_is_active(fight) do
			to.fights_hp[fight.title] -= 5
			to_hp = to.fights_hp[fight.title]
			to.save
			return "#{from.user_name} punches #{to.user_name}! -5HP #{to_hp}/#{TotalHitPoints}"
		end
	end

end

class Fight
	include MongoMapper::Document
	# a new fight is created when a fighter mentions another
	key :status, String # active when the second user has accepted the fight
	key :title, String # so we can identify a fight based on both usernames but without looking up challenger and challenged
	key :challenger, String
	key :challenged, String

	many :fight_actions
end

class FightAction
	include MongoMapper::EmbeddedDocument
	# logs each action taken during a fight
	key :from, String
	key :move, String
	key :to, String

	timestamps!

end

class Fighter
	include MongoMapper::Document
	# stores stats on each fighter

	key :user_name, String
	key :xp_points, Integer
	key :fights_hp, Hash
end




MOVES = Moves.new	# a constant to hold a singleton Moves object

### ACTIONS AND CONTROLLERS
class Listener
	def initialize
		# a basic listener for command-line testing
		# listen for input from STDIN and pass on the message

		puts "listener initialized."
		puts ""
		puts "available commands:"

		instance_methods = Moves.instance_methods false
		puts instance_methods[2..-1]
	end
	
	def listen_gets
		while true do
		  input = gets.chomp
		  #puts "> #{input}"

		  if input == 'break'
		    break

		  else
		  	if !input.empty?
		  		action = Action.new input
		  		result = action.execute
		  		puts result
		  	end

		  	# tweet the result
		  end
		end # while
	end


end # class Listener



class Action
	# every tweet creates an action. that action creates or updates fights and player hp, and returns a result which is tweeted

	def initialize(input)
		inputs 	= input.split " "

		@from 	= get_fighter inputs[0]		# assign a fighter object or create one
		@type 	= inputs[1...-1].join("_")
		@to   	= get_fighter inputs[-1]	# assign a fighter object or create one

		@title  = get_title			# get the fight id for looking up fights; created from a hash of both users, sorted 		
		@fight 	= get_fight					# assign a fight object or create one
		

		debug "init action {from: #{@from.user_name}, type:#{@type}, to: #{@to.user_name}"
	end

	def execute
		debug "execute action #{@type.to_sym}"
		result = MOVES.__send__(@type.to_sym, @fight, @from, @to)
		save_log unless result == false

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

	# return the winner or false if win condition not yet met
	def check_for_winner
	
		if @from.fights_hp[@title] <= 0 
			return @to
		
		elsif @to.fights_hp[@title] <= 0
			return @from
		else
			return false
		end
	end

	def save_log
		@fight.fight_actions << FightAction.new(:from => @from.user_name, :move => @type, :to => @to.user_name)
		@fight.save!
	end

	def get_fighter(name)
		fighter = Fighter.where(:user_name => name).first

		if fighter.nil?
			fighter = Fighter.create(:user_name => name, :xp_points => 0)
			fighter.save
		end

		return fighter
	end

	def get_title
		# TODO: move this into the Fight class; could probably be created automatically
		return [@from.user_name, @to.user_name].sort.join "_vs_"
	end

	def get_fight
		
		fight = Fight.where(:title => @title).first
		#byebug
		if fight.nil?
			debug "new fight created: #{@title}"

			fight = Fight.new(:title => @title, :status => "inactive", :challenger => @from.user_name, :challenged => @to.user_name)
			fight.save
					
		else
			debug "using existing fight."
		end

		return fight
	end



end

### TESTS
def test_execute(command)
	action = Action.new command
	result = action.execute
	puts result
end

def test_u1_vs_u2
	test_execute "u1 challenge u2"
	test_execute "u2 accept u1"
	5.times do test_execute "u1 punch u2" end
	
end

# runtime
configure

# for testing
Fight.destroy_all
Fighter.destroy_all

# CONSOLE MODE
#listener = Listener.new
#listener.listen_gets

# TEST MODE
test_u1_vs_u2




