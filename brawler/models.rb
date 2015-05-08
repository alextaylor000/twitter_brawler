# models.rb
# MongoDB database models definitions

### MODELS
require 'mongo_mapper'	# for db hooks

class Fight
	include MongoMapper::Document
	# a new fight is created when a fighter mentions another
	key :status, String # active when the second user has accepted the fight
	key :title, String # so we can identify a fight based on both usernames but without looking up challenger and challenged
	key :challenger, String
	key :challenged, String
	key :initiative, String
	key :pending_move, Hash # the move gets stored here until the receiving user has a chance to block. stores the from_user, to_user, move name and base attack

	many :fight_actions
end

class FightAction
	include MongoMapper::EmbeddedDocument
	# logs each action taken during a fight
	key :from, String
	key :move, String
	key :to, String

	timestamps!

end

class Fighter
	include MongoMapper::Document
	# stores stats on each fighter

	key :user_name, String
	key :xp_points, Integer
	key :fights_hp, Hash
end

class TweetQueue
	include MongoMapper::Document
	# stores tweets created by an action that are waiting to be sent

	key :text, String
	key :source_id, Integer

	timestamps!
end