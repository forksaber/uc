require 'uc/logger'
require 'uc/mqueue'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class ReadyEvent

      include Logger
      include Helper

      attr_reader :ready_wait, :server, :worker

      def initialize(server, worker, ready_wait: nil)
        @server = server
        @worker = worker
        @ready_wait = ready_wait
      end

      def run
        event_stream.info "worker #{id} ready"
        if not last_worker?
          notify if ready_wait
        end
      end

      def notify
        mq.create
        mq.clear
        mq.nb_writer do |writer|
          writer.send ready_event
        end
      rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES => e
        event_stream.warn "ready event not sent for worker #{id}: #{e.class}"
      end

      def mq
        @mq ||= ::Uc::Mqueue.new(ready_queue, max_msg: 10, msg_size: 30)
      end

    end
  end
end
