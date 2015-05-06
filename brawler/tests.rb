# tests.rb
# Generate test fights here to see the result of a fight without using the console
# Commands should be of the format "from_user action to_user", e.g. "user1 punch user2"

require File.expand_path(File.dirname(__FILE__) + '/config') 	# models.rb
require File.expand_path(File.dirname(__FILE__) + '/action') 	# brawler.rb

### TESTS
def test_execute(command)
	puts "> #{command}"
	action = Action.new command
	result = action.execute
	puts result
end

def test_u1_vs_u2
	test_execute "u1 challenge u2"
	test_execute "u2 accept u1"
	3.times do test_execute "u1 hammerfist u2" end

end


### RUN TESTS
test_u1_vs_u2