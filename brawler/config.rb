# config.rb
# Sets up the database

require 'mongo_mapper'

def configure
	MongoMapper.database = "twtfudb"
end

configure