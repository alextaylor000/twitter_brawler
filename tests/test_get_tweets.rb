require 'twitter'
require 'byebug'

# authenticate
client = Twitter::REST::Client.new do |config|
	config.consumer_key			= ENV['TWTFU_CONSUMER_KEY']
	config.consumer_secret 		= ENV['TWTFU_CONSUMER_SECRET']
end

# get some tweets
user 		= 'mctaylorpants'
options 	= { count: 5 }

tweets = client.user_timeline(user, options)

tweets.each do |t|
	puts t.text
end
