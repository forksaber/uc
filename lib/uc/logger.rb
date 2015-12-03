require 'logger'
require 'uc/custom_logger'
require 'uc/event_stream'
require 'securerandom'

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
      @logger ||= ::Uc::CustomLogger.new(STDOUT)
    end

    def self.stderr
      @stderr ||= ::Logger.new(STDERR)
    end

    def self.event_stream
      @event_stream ||= ::Uc::EventStream.new(event_queue)
    end

    def self.run_id
      @run_id ||= SecureRandom.hex(3)
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

    def run_id
      ::Uc::Logger.run_id
    end
  end
end
