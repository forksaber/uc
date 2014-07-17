require 'uc/mqueue'
require 'uc/logger'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class ReadyWait

      include ::Uc::Logger
      include ::Uc::Unicorn::Helper


      attr_accessor :run_id
      attr_reader :ready_wait, :server, :worker


      def initialize(server, worker, run_id: nil, ready_wait: ready_wait)
        @server = server
        @worker = worker
        @run_id = run_id
        @ready_wait = ready_wait
      end

      def run
        wait if ready_wait
      end

      def queue_name
         @queue_name ||= "#{event_queue}_ready_#{worker.nr}"
      end

      def id
        @id ||= worker.nr + 1
      end

      def wait
        if first_worker?
          event_stream.debug "no wait for worker #{worker.nr}"
          return
        end
        mq.create
        msg = mq.wait(event, ready_wait)
        event_stream.debug "ack worker ready #{worker.nr}"
      rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES, Errno::ETIMEDOUT => e
        event_stream.warn "ready wait error #{worker.nr}: #{e.class}"
      end

      def event
        run_id ? "ready_#{run_id}" : "ready" 
      end

      def mq
        @mq ||= ::Uc::Mqueue.new(queue_name, max_msg: 10, msg_size: 30)
      end

    end
  end
end
