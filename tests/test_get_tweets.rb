require 'twitter'
require 'byebug'

# authenticate
client = Twitter::REST::Client.new do |config|
	config.consumer_key		= "zDmEO0YsvZE0T5xd6bRzBUXwo"
	config.consumer_secret	= "d3yJLYDSFiF1rliVZKdR3yARlrr8hAextuJpdcUMgOXhT8mucV"
end

# get some tweets
user 		= 'mctaylorpants'
options 	= { count: 5 }

tweets = client.user_timeline(user, options)

tweets.each do |t|
	puts t.text
end





