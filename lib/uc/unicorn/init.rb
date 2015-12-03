require 'uc/unicorn/helper'
require 'uc/error'
require 'uc/logger'

module Uc
  module Unicorn
    class Init

      include Logger
      include Helper

      attr_accessor :server

      def initialize(server)
        @server = server
      end

      def event_type
        @event_type ||= (restart? ? "restart" : "start")
      end

      def run
        event_stream.debug "event_type #{event_type}"
      end

      def run_once
        return if @ran_once
        @ran_once = true
        run
      end

      def end_run(worker)
        last_worker = ((worker.nr + 1) == server.worker_processes)
        if last_worker
          event_stream.pub :fin, "server #{event_type}" 
        end
      end

    end
  end
end
