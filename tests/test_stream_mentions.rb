require 'twitter'
require 'byebug'

streamclient = Twitter::Streaming::Client.new do |config|
	config.consumer_key			= "zDmEO0YsvZE0T5xd6bRzBUXwo"
	config.consumer_secret 		= "d3yJLYDSFiF1rliVZKdR3yARlrr8hAextuJpdcUMgOXhT8mucV"
	config.access_token			= "24545446-ttxdsom9ZWuResP7RBb65pz9tqydkRX4I2aobw6SX"
	config.access_token_secret	= "ZElRBLttQhVYGEluEC6WlQWBE5eqwnwpP8nL1jQ2ZY4Uk"
end

# filter creates an endless stream
username = 'CNN'

streamclient.filter(track:username) do |tweet|
	if tweet.user_mentions?
		mentions = tweet.user_mentions

		mentions.each do |m|
			if m.screen_name == username
				puts tweet.text
			end
		end
	end


  # it can be broken ... with break
  #break
end
