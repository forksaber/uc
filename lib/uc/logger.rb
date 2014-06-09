require 'logger'
require 'uc/mq_logger'
module Uc
  module Logger
   
    def self.logger
      @logger ||= begin
        logger = ::Logger.new(STDOUT)
        logger.formatter = proc do |severity, datetime, progname, msg|
          if severity == "INFO"
            "#{msg}\n"
          else
            "#{severity} #{msg}\n"
          end
        end
        logger.level = ::Logger::INFO
        logger
      end
    end

    def logger
      ::Uc::Logger.logger
    end

    def mq_log(msg)
      return if not respond_to? :queue_name
      @mq_logger ||= ::Uc::MqLogger.new(queue_name)
      @mq_logger.log msg 
    end 

  end
end
