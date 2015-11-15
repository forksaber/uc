require 'uc/unicorn/helper'
require 'uc/error'
require 'uc/logger'

module Uc
  module Unicorn
    class Init

      include ::Uc::Logger
      include ::Uc::Unicorn::Helper

      attr_accessor :server, :worker

      def initialize(server)
        @server = server
      end

      def event_type
        @event_type ||= (restart? ? "restart" : "start")
      end

      def run
        event_stream.debug "event_type #{event_type}"
        acquired = acquire_lock
        if not acquired
          error_msg = "unable to acquire shared lock (unicorn)"
          event_stream.fatal error_msg
          raise ::Uc::Error, error_msg
        end
      end

      def acquire_lock
        lock_acquired = lock_fd.flock(File::LOCK_SH | File::LOCK_NB )
       rescue => e
        stderr.error "#{e.class} #{e.message}\n #{e.backtrace.join("\n")}"
        return false
      end

      def run_once
       return if @ran_once
       @ran_once = true
       run
      end

      def lock_fd
        @lock_fd ||= File.new("tmp/unicorn.lock", "a+")
      end

      def end_run(worker)
        @worker = worker
        if last_worker?
          event_stream.pub :fin, "server #{event_type}" 
        end
      end

    end
  end
end
