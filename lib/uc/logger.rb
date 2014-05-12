require 'logger'
module Uc
  module Logger
   
    def self.logger
      @logger ||= begin
        logger = ::Logger.new(STDOUT)
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        logger.level = ::Logger::INFO
        logger
      end
    end 

    def logger
      ::Uc::Logger.logger
    end

  end
end
