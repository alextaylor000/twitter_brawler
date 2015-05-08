require 'timeout'

begin
puts "start"
status = Timeout::timeout(1) {
  while true do 
  	#
  end
}

rescue Timeout::Error
	#
ensure
	puts "end"
end

