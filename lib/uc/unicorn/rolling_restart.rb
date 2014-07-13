require 'uc/mqueue'
require 'uc/logger'
module Uc; module Unicorn
  class RollingRestart

    include ::Uc::Logger
    attr_reader :server, :worker, :queue_name, :prestart_wait, :sleep_secs
    attr_accessor :run_id

    def initialize(server, worker, queue_name, prestart_wait: nil, sleep_secs: 0.1)
      @server = server
      @worker = worker
      @queue_name = queue_name
      @prestart_wait = prestart_wait
      @sleep_secs = sleep_secs
    end

    def run
      return if not (server && worker)
      return if not restart?

      destroy_prestart_queues
      wait_for_prestart_end_event
      sleep sleep_secs if not first_worker?
      kill_old_worker
    end

    private

    def prestart_mq
      @prestart_mq ||= ::Uc::Mqueue.new(prestart_queue, max_msg: 10, msg_size: 30)
    end

    def destroy_prestart_queues
      return if not first_worker?
      (0..server.worker_processes).each do |i|
        mq = ::Uc::Mqueue.new("#{queue_name}_prestart_#{i}")
        mq.destroy
      end
    end
 
    def prestart_queue
      first_worker? ? nil : "#{queue_name}_prestart_#{worker.nr - 1}"
    end

    def wait_for_prestart_end_event
      return if not prestart_wait
      if not prestart_queue
        logger.debug "[rr] no ps wait for #{worker.nr + 1}"
        return
      end
      begin
        prestart_mq.create
        msg = prestart_mq.wait( prestart_end_event, prestart_wait)
        logger.debug "[rr] ps end event #{prestart_end_event} for #{ worker.nr + 1}"
      rescue => e
        logger.info "#{e.class} #{e.message}"
      end
    end

    def kill_old_worker
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
      event_stream.info "starting worker #{worker.nr + 1}"
      event_stream.pub "fin", "restart successful" if sig == :QUIT
    rescue Errno::ENOENT, Errno::ESRCH, Errno::EAGAIN, Errno::EACCES => e
      logger.error "rolling restart #{e.class} #{e.message}"
    end

    def prestart_end_event
      run_id ? "prestart_end_#{run_id}" : "prestart_end"
    end

    def restart?
      old_pid != server.pid
    end

    def first_worker?
      worker.nr == 0
    end
    
    def old_pid
      "#{server.config[:pid]}.oldbin"
    end
  
  end
end; end
