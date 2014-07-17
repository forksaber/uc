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
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        event_stream.debug "stopping old worker #{id}"
        Process.kill(sig, File.read(old_pid).to_i)
        event_stream.debug "stopped old worker #{id}"

      rescue Errno::ENOENT, Errno::ESRCH, Errno::EAGAIN, Errno::EACCES => e
        event_stream.warn "error while stopping worker #{worker.nr + 1}, #{e.class}"
        logger.info "shutdown_error id #{id}| #{e.class} #{e.message}"
      end

      def id
        @id ||= (worker.nr + 1)
      end

    end

  end
end

