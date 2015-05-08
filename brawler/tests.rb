# tests.rb
# Generate test fights here to see the result of a fight without using the console
# Commands should be of the format "from_user action to_user", e.g. "user1 punch user2"
require 'byebug'

require File.expand_path(File.dirname(__FILE__) + '/config') 	# models.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# brawler.rb

### TESTS
def test_execute(command)
	puts "> #{command}"
	action = Action.new command
	result = action.execute
	puts result
end

def reset_db
	# for testing
	Fight.destroy_all
	Fighter.destroy_all	
end

def test_u1_vs_u2
	reset_db
	test_execute "u1 challenge u2"
	test_execute "u2 accept u1"
	test_execute "u1 hammerfist u2"
	test_execute "u2 hammerfist u1"
	test_execute "u1 hammerfist u2"
	test_execute "u1 hammerfist u2"
	test_execute "u2 hammerfist u1"
end

def test_blocking
	reset_db
	test_execute "user1 challenge user2"
	test_execute "user2 accept user1"
	test_execute "user1 hammerfist user2"
	test_execute "user2 block user1"
end

def test_threading
	reset_db
	test_execute "u1 challenge u2"
	test_execute "u2 accept u1"
	test_execute "u1 hammerfist u2"
end

reset_db

### RUN TESTS
test_threading

