# tests.rb
# Generate test fights here to see the result of a fight without using the console
# Commands should be of the format "from_user action to_user", e.g. "user1 punch user2"
require 'byebug'

require File.expand_path(File.dirname(__FILE__) + '/debug') 	# debug.rb
require File.expand_path(File.dirname(__FILE__) + '/config') 	# models.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# brawler.rb

### TESTS
def test_execute(from, text, to)
	puts "> #{from} #{text} #{to}"
	action = Action.new from, text, to
	result = action.execute
	puts result
end

def reset_db
	# for testing
	Fight.destroy_all
	Fighter.destroy_all	
	TweetQueue.destroy_all
end


def test_threading
	reset_db
	test_execute "u1", "challenge", "u2"
end

reset_db

### RUN TESTS
test_threading

