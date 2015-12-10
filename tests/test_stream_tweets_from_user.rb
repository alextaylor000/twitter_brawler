require 'twitter'

streamclient = Twitter::Streaming::Client.new do |config|
	config.consumer_key			= ENV['TWTFU_CONSUMER_KEY']
	config.consumer_secret 		= ENV['TWTFU_CONSUMER_SECRET']
	config.access_token			= ENV['TWTFU_ACCESS_TOKEN']
	config.access_token_secret	= ENV['TWTFU_ACCESS_TOKEN_SECRET']
end

# filter creates an endless stream
streamclient.filter(follow:'mctaylorpants') do |tweet|
  puts tweet.text

  # it can be broken ... with break
  break
end
