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

def configure
	MongoMapper.database = "twtfudb"
end


class Listener
	def initialize
		@receiver = Receiver.new

		puts "listener initialized."
		puts ""
		puts "available commands:"

		instance_methods = Receiver.instance_methods false
		puts instance_methods[1..-1]
	end

	# listen for input from STDIN and pass on the message
	def listen_gets

		while true do
		  input = gets.chomp
		  puts "> #{input}"

		  if input == 'break'
		    break
		  else
		  	parse input
		  end
		end # while
	end

	def parse(input)
		# "user1 punch user2" gets split on spaces
		challenger, verb, challenged = input.split(" ")		

		@receiver.send(verb.to_sym)
	end


end # class Listener

class Receiver
	def method_missing(method_name, *args, &block)
		puts "I don't understand #{method_name}"
	end

	def brawl(fighter_challenger, fighter_challenged)
		puts "let's brawl"
	end

	def punch
		puts "punch!"
	end


end # class Receiver

class Fight
	include MongoMapper::Document
	# a new fight is created when a fighter mentions another
	
	key :challenger, String
	key :challenged, String
	key :id_fight, String # SecureRandom.uuid
	key :log, Array
end


class Fighter
	include MongoMapper::Document
	# stores stats on each fighter

	key :user_name, String
	key :xp_points, Integer
	key :fights_hp, Hash
end



# runtime
listener = Listener.new
listener.listen_gets




