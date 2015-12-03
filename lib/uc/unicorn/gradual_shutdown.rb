require 'uc/logger'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class GradualShutdown

      include Logger
      include Helper

      attr_reader :server, :worker

      def initialize(server, worker)
        @server = server
        @worker = worker
      end

      def run
        return if not restart?
        event_stream.debug "stopping old worker #{id}"
        if kill sig
          event_stream.debug("stopped old worker #{id}")
        end
      rescue => e
        log_error e
      end

      private

      def sig
        (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      end

      def kill(sig)
        Process.kill(sig, File.read(old_pid).to_i)
      end

      def log_error(e)
        stderr.info "error while stopping worker #{id}| #{e.class} #{e.message}"
        event_stream.warn "error while stopping worker #{id}, #{e.class}"
      end

    end
  end
end
