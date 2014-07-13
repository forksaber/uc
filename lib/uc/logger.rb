require 'logger'
require 'uc/event_stream'
module Uc
  module Logger

    class << self
      attr_accessor :event_queue
    end

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

    def self.event_stream
      @event_stream ||= ::Uc::EventStream.new(event_queue)
    end

    def event_stream
      ::Uc::Logger.event_stream
    end

    def logger
      ::Uc::Logger.logger
    end

  end
end
