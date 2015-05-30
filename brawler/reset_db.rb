# resets all db models
require File.expand_path(File.dirname(__FILE__) + '/config') 	# config.rb
require File.expand_path(File.dirname(__FILE__) + '/models') 	# models.rb

Fight.destroy_all
Fighter.destroy_all	
TweetQueue.destroy_all
TweetID.destroy_all

