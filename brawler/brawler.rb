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
FightInitiationWord = 'challenge'

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

	# default action for missing methods
	def method_missing(method_name, *args, &block)
		puts "I don't understand #{method_name}"
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

			return "fight accepted. FIGHT!"

		end
	end



	def punch(fight, from, to)
		puts "punch!"
	end

end

class Fight
	include MongoMapper::Document
	# a new fight is created when a fighter mentions another
	key :status, String # active when the second user has accepted the fight
	key :fight_id, String # so we can identify a fight based on both usernames but without looking up challenger and challenged
	key :challenger, String
	key :challenged, String
	key :log, Array
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
		puts instance_methods[1..-1]
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

		@fight 	= get_fight					# assign a fight object or create one
		@fight_id = get_fight_id			# get the fight id for looking up fights; created from a hash of both users, sorted 

		debug "init action {from: #{@from.user_name}, type:#{@type}, to: #{@to.user_name}"
	end

	def execute
		debug "execute action #{@type.to_sym}"
		return MOVES.__send__(@type.to_sym, @fight, @from, @to)
	end

	def get_fighter(name)
		fighter = Fighter.where(:user_name => name).first

		if fighter.nil?
			fighter = Fighter.create(:user_name => name, :xp_points => 0)
			fighter.save
		end

		return fighter
	end

	def get_fight_id
		key = [@from.user_name, @to.user_name].sort.join "-"
		fight_id = Digest::SHA256.hexdigest key
		debug "fight id #{key} = #{fight_id}"

		return fight_id
	end

	def get_fight
		
		fight = Fight.where(:fight_id => @fight_id).first
		#byebug
		if fight.nil?
			debug "new fight created."

			fight = Fight.new(:fight_id => @fight_id, :status => "inactive", :challenger => @from.user_name, :challenged => @to.user_name)
			fight.log << @type # TODO: the log may have to become its own model if we want to store stuff like timestamps and full actions
			fight.save
		
		else
			debug "using existing fight."
		end

		return fight
	end



end







# runtime
configure

# for testing
Fight.destroy_all
Fighter.destroy_all

listener = Listener.new
listener.listen_gets




