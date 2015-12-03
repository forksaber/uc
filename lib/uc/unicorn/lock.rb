require 'uc/logger'

module Uc
  module Unicorn
    class Lock

      include Logger

      def acquire
        lock_fd.flock(File::LOCK_SH | File::LOCK_NB)
      rescue => e
        stderr.error "#{e.class} #{e.message}\n #{e.backtrace.join("\n")}"
        return false
      end

      private

      def lock_fd
        @lock_fd ||= File.new("tmp/unicorn.lock", "a+")
      end
    
    end
  end
end
