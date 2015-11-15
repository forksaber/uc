require 'uc/logger'
require 'uc/mqueue'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class ReadyEvent

      include ::Uc::Logger
      include ::Uc::Unicorn::Helper

      attr_accessor :run_id
      attr_reader :ready_wait, :server, :worker


      def initialize(server, worker, run_id: nil, ready_wait: nil)
        @server = server
        @worker = worker
        @run_id = run_id
        @ready_wait = ready_wait
        @queue_name ||= "#{event_queue}_ready"
      end

      def run
        event_stream.info "worker #{id} ready"
        if not last_worker?
          notify if ready_wait
        end
      #    event_stream.pub :fin, "server #{server_event} successful"
      end

      def notify
        mq.create
        mq.clear
        msg = mq.nb_writer do |writer|
          writer.send event
        end
      rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES => e
        event_stream.warn "ready event not sent for worker #{id}: #{e.class}"
      end

      def event
        run_id ? "ready_#{run_id}" : "ready" 
      end

      def mq
        @mq ||= ::Uc::Mqueue.new(@queue_name, max_msg: 10, msg_size: 30)
      end

    end
  end
end
