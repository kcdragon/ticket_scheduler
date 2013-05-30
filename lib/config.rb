require 'yaml'

module TicketScheduler
  class Config
    CONFIG_FILE = File.dirname(File.expand_path(__FILE__)) + '/../config/config.yml'

    def self.instance
      @@instance ||= Config.new
    end

    attr_reader :host, :port
    
    def initialize
      config = YAML.load_file CONFIG_FILE
      @host = config['database']['host']
      @port = config['database']['port']
    end
  end
end
