module Uc
  module Unicorn
    module Helper

      def restart?
        (File.readable? old_pid) && (server.pid != old_pid)
      end

      def first_worker?
        worker.nr == 0
      end
          
      def last_worker?
        (worker.nr + 1) == server.worker_processes
      end
 
      def old_pid
        "#{server.config[:pid]}.oldbin"
      end

      def id
        worker.nr + 1
      end

      def ready_queue
        "#{event_queue}_ready"
      end

      def ready_event
        run_id ? "ready_#{run_id}" : "ready"
      end

    end
  end
end

