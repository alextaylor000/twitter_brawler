# bot.rb
# The Twitter bot responsible for receiving and sending tweets. Powered by chatterbot.

require 'chatterbot/dsl'

# TODO: make these environment variables
consumer_key 'e6IZLNgC4tFd7EzMOW0PepruG'
consumer_secret 'tI4UQog02tRsDMgDuJP9X2ZE9DoJM2K5rEGbXSaWPDN8qw9gT2'
secret 'LKuuyh7smscGxp550KnEaFvMUCqFnwCdhDQJNhTFUWxjp' 
token '3228612387-xeQ9dwHVZIZaYYopbyPRzI6SyjVNFTQRW6VinsM'

#
#
#
#


streaming do
	
	replies do |tweet|
		puts ">> #{tweet.text}"
	end

end