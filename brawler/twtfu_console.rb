# twtfu_console.rb
# A console implementation of twtfu, for testing purposes
# Commands are of the format "from_user action to_user", e.g. "user1 punch user2"
# To start a fight:
# user1 challenge user2
# user2 accept user1
# user1 punch user2
# etc ...


# twitfu - a twitter fighting game
#
# the Listener object listens for input and passes it on to Action
# in order to process commands
#
# Action acts as a controller to parse the command and issue the
# command to a matching method within Moves
#
# The method within Moves calculates the effect of the action (e.g. initiating a fight, doing damage)
# and sends its result back to Action, where it can be processed and send back to the listener
#
# an invalid method name passed to Moves will trigger the method_missing
# method within Moves

require 'byebug' 		# for debugging

require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# action.rb

DEBUG = true


def debug(msg)
	if DEBUG
		puts "* #{msg}"
	end
end


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


# for testing
Fight.destroy_all
Fighter.destroy_all

# CONSOLE MODE
listener = Listener.new
listener.listen_gets





