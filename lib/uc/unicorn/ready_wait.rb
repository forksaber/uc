require 'uc/mqueue'
require 'uc/logger'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class ReadyWait

      include Logger
      include Helper

      attr_reader :ready_wait, :server, :worker

      def initialize(server, worker, ready_wait: nil)
        @server = server
        @worker = worker
        @ready_wait = ready_wait
      end

      def run
        wait if ready_wait
      end

      def wait
        if first_worker?
          event_stream.debug "no wait for worker #{worker.nr}"
          return
        end
        mq.create
        msg = mq.wait(ready_event, ready_wait)
        event_stream.debug "ack worker ready #{worker.nr}"
      rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES, Errno::ETIMEDOUT => e
        event_stream.warn "ready wait error #{worker.nr}: #{e.class}"
      end

      def mq
        @mq ||= ::Uc::Mqueue.new(ready_queue, max_msg: 10, msg_size: 30)
      end

    end
  end
end
