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

Thread.abort_on_exception=true # for debugging

require 'byebug' 		# for debugging

require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# action.rb



### ACTIONS AND CONTROLLERS
class Listener
	def initialize
		# a basic listener for command-line testing
		# listen for input from STDIN and pass on the message

		puts "listener initialized."
		puts ""
		puts "available commands:"

		instance_methods = Moves.instance_methods false
		puts instance_methods
	end
	
	def listen_gets
		while true do
		  input = gets.chomp
		  #puts "> #{input}"

		  if input == 'break'
		    break

		  else

		  	if !input.empty?
		  		# spawn a new thread so that the action can wait a set amount of time for a block move without...well, blocking.
		  		#byebug # to navigate threads: thread switch, thread stop (main thread)
		  		Thread.new {
		  			
		  			input_split = input.split(" ")

		  			# for test purposes, swap out the username for something 15 chars long
		  			from = debug_replace_username input_split[0]
		  			to = debug_replace_username input_split[2]


			  		action = Action.new from, input_split[1], to  # from, text, to

			  		if action.fight
				  		result = action.execute
				  		puts result
				  	end
			  	}
		  	end

		  	# tweet the result
		  end
		end # while
	end

	def debug_replace_username(name)
		name << "_______________"
		return name[0..14]
	end


end # class Listener


# for testing
Fight.destroy_all
Fighter.destroy_all
TweetQueue.destroy_all


# CONSOLE MODE
listener = Listener.new
listener.listen_gets





