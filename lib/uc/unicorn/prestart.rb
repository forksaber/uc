require 'uc/logger'
require 'uc/mqueue'

module Uc; module Unicorn;
  class Prestart

    include ::Uc::Logger

    attr_reader :server, :worker, :queue_name, :url
    attr_accessor :run_id

    def initialize(server, worker, queue_name, url: "/", run_id: nil)
      @server = server
      @worker = worker
      @url = url
      @queue_name = queue_name
      @run_id = run_id
    end

    def app
      @app ||= server.instance_variable_get("@app")
    end

    def run
      response = app.call(rack_request)
      body = response[2]
      if body.is_a? Rack::BodyProxy
        body.close
      end
      end_prestart
    rescue => e
      logger.warn "pre start failed for worker : #{e.message}"
    end


    private

    def worker_id
      worker.nr + 1
    end

    def rack_request
      Rack::MockRequest.env_for("http://127.0.0.1/#{url}")
    end

    def last_worker?
      (worker.nr + 1) == server.worker_processes
    end 

    def end_prestart
      if last_worker?
        logger.info "[ps] no_event #{worker_id}"
        return
      end
      logger.info "[ps] start #{worker_id}"
      send_prestart_end
      event_stream.info "prestart end worker #{worker_id}"
      logger.info "[ps] end #{worker_id}"
    end

    def send_prestart_end
      mq.create
      mq.clear
      mq.nb_writer do |writer|
        writer.send prestart_end_event
      end
    rescue Errno::ENOENT, Errno::EAGAIN, Errno::EACCES => e
      logger.warn "prestart failed for worker #{worker.nr + 1}: #{e.class}"
    end

    def prestart_end_event
      run_id ? "prestart_end_#{run_id}" : "prestart_end" 
    end

    def mq
      @mq ||= ::Uc::Mqueue.new(prestart_queue_name, max_msg: 10, msg_size: 30)
    end

    def prestart_queue_name
      "#{queue_name}_prestart_#{worker.nr}"
    end

  end
end; end

