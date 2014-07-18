require 'uc/logger'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
  
    class GradualShutdown

      include ::Uc::Logger
      include ::Uc::Unicorn::Helper

      attr_reader :server, :worker

      def initialize(server, worker)
        @server = server
        @worker = worker
      end

      def run
        return if not (server && worker)
        return if not restart?
        shutdown_old_master 
      end

      def shutdown_old_master
        event_stream.debug "stopping old worker #{id}"
        if send_signal
          event_stream.debug "stopped old worker #{id}"
        end
      end

      def sig
        (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      end

      def send_signal
        Process.kill(sig, File.read(old_pid).to_i)
        return true
      rescue => e
        log_kill_error e
        return false
      end

      def log_kill_error(e)
        stderr.info "error sending kill signal #{id}| #{e.class} #{e.message}"
        event_stream.warn "error while stopping worker #{worker.nr + 1}, #{e.class}"
      end

      def id
        @id ||= (worker.nr + 1)
      end

    end

  end
end

