require 'logger'
require 'uc/event_stream'
module Uc
  module Logger

    class << self
      attr_reader :event_queue
    end

    def self.event_queue=(queue_name)
      @event_stream = nil
      @event_queue = queue_name
    end

    def self.logger
      @logger ||= begin
        logger = ::Logger.new(STDOUT)
        logger.formatter = proc do |severity, datetime, progname, msg|
          case severity
          when "INFO"
            "#{msg}\n"
          when "ERROR"
            "#{severity.downcase.bold.red} #{msg}\n"
          else
            "#{severity.downcase.bold.blue} #{msg}\n"
          end
        end
        logger.level = ::Logger::INFO
        logger
      end
    end

    def self.stderr
      @stderr ||= ::Logger.new(STDERR)
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

    def stderr
      ::Uc::Logger.stderr
    end

    def event_queue
      ::Uc::Logger.event_queue
    end
  end
end
