require 'twitter'

streamclient = Twitter::Streaming::Client.new do |config|
	config.consumer_key			= "e6IZLNgC4tFd7EzMOW0PepruG"
	config.consumer_secret 		= "tI4UQog02tRsDMgDuJP9X2ZE9DoJM2K5rEGbXSaWPDN8qw9gT2"
	config.access_token			= "3228612387-xeQ9dwHVZIZaYYopbyPRzI6SyjVNFTQRW6VinsM"
	config.access_token_secret	= "LKuuyh7smscGxp550KnEaFvMUCqFnwCdhDQJNhTFUWxjp"
end

# filter creates an endless stream
streamclient.filter(locations: "-122.75,36.8,-121.75,37.8") do |tweet|
  puts tweet.text

  # it can be broken ... with break
  break
end
