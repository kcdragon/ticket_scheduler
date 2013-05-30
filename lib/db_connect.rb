require 'mongo'

require_relative 'config'

module TicketScheduler
  class DbConnect
    include Mongo

    attr_reader :db
    
    def self.instance
      @@instance ||= DbConnect.new
    end

    def initialize
      config = Config.instance
      @client = MongoClient.new config.host, config.port
    end

    def set_database name
      @db = @client.db name
    end
    
    def drop_database name
      @client.drop_database name  
    end

    def close
      @client.close
    end
  end
end
