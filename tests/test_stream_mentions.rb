require 'twitter'
require 'byebug'

streamclient = Twitter::Streaming::Client.new do |config|
	config.consumer_key			= ENV['TWTFU_CONSUMER_KEY']
	config.consumer_secret 		= ENV['TWTFU_CONSUMER_SECRET']
	config.access_token			= ENV['TWTFU_ACCESS_TOKEN']
	config.access_token_secret	= ENV['TWTFU_ACCESS_TOKEN_SECRET']
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
