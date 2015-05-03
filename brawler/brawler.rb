# brawler - a twitter fighting game
#
# the Listener object listens for input and passes it on to Receiver
# in order to process commands, Receiver should implement a function 
# for each command, with optional arguments
#
# an invalid method name passed to Receiver will trigger the method_missing
# method within Receiver
require 'mongo_mapper'
require 'byebug'

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
	# check out my sweet moves
	def method_missing(method_name, *args, &block)
		puts "I don't understand #{method_name}"
	end

	def accept # accept a fighter's challenge

	end

	def punch
		puts "punch!"
	end

end

class Fight
	include MongoMapper::Document
	# a new fight is created when a fighter mentions another
	key :active, Boolean # active when the second user has accepted the fight
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
		  puts "> #{input}"

		  if input == 'break'
		    break
		  else
		  	action = Action.new input
		  	result = action.execute
		  	# tweet the result
		  end
		end # while
	end


end # class Listener



class Action
	# every tweet creates an action. that action creates or updates fights and player hp, and returns a result which is tweeted

	def initialize(input)
		inputs 	= input.split " "

		@from 	= get_fighter inputs[0]
		@type 	= inputs[1...-1].join("_")
		@to   	= get_fighter inputs[-1]

		@result	= ""

		debug "init action {from: #{@from}, type:#{@type}, to: #{@to}"
	end

	def execute
		debug "execute action"
		#byebug
		# store the fight
		if Fight.where(:challenger => @from, :challenged => @to).count > 0
			MOVES.__send__(@type.to_sym)

		else
			new_fight if @type == FightInitiationWord
			return "#{@from} challenged #{@to}. accept?"

		end

		
	end

	def get_fighter(name)
		byebug
		fighter = Fighter.where(:user_name => name).first

		if fighter.nil?
			fighter = Fighter.create(:user_name => name, :xp_points => 0)
			fighter.save
		end

		return fighter
	end


	def new_fight
		debug "new fight initiated!"
		fight = Fight.new(:active => false, :challenger => @from, :challenged => @to)
		fight.log << @type # TODO: the log may have to become its own model if we want to store stuff like timestamps and full actions
		fight.save
	end



end







# runtime
configure

# for testing
Fight.destroy_all
Fighter.destroy_all

listener = Listener.new
listener.listen_gets




