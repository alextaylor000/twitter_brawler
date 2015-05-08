require 'twitter'
require 'byebug'

# authenticate
client = Twitter::REST::Client.new do |config|
	config.consumer_key			= "e6IZLNgC4tFd7EzMOW0PepruG"
	config.consumer_secret 		= "tI4UQog02tRsDMgDuJP9X2ZE9DoJM2K5rEGbXSaWPDN8qw9gT2"
#	config.access_token			= "3228612387-xeQ9dwHVZIZaYYopbyPRzI6SyjVNFTQRW6VinsM"
#	config.access_token_secret	= "LKuuyh7smscGxp550KnEaFvMUCqFnwCdhDQJNhTFUWxjp"
end

# get some tweets
user 		= 'mctaylorpants'
options 	= { count: 5 }

tweets = client.user_timeline(user, options)

tweets.each do |t|
	puts t.text
end





