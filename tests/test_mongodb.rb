# https://gist.github.com/wxmn/665675 has some good info on embedded docs!

require 'mongo_mapper'
MongoMapper.database = "test"

class Story
	include MongoMapper::Document

	key :title, String
	key :text, String

	timestamps!

	many :comments
end

class Comment
	include MongoMapper::EmbeddedDocument

	key :user, String
	key :comment, String

	timestamps!
end

class TweetID
	include MongoMapper::Document
	# an index of IDs of recently sent tweets, to detect duplicate tweets
	key :tweet_id, Integer

	timestamps!
end


# wipe db at runtime for testing
Story.destroy_all

	


