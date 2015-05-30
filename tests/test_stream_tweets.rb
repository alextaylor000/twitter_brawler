require 'twitter'
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb

# filter creates an endless stream
streamclient.user(follow:"@twtfu") do |tweet|
  puts tweet.text

  # it can be broken ... with break
  #break
end
