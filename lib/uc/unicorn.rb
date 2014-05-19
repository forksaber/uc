require 'uc/mqueue'
module Uc
  module Unicorn

    def self.queue_file
      "config/unicorn_mq"
    end

    def self.rolling_restart(server, worker, queue_name: nil, sleep_secs: 1)
      queue_name ||= get_queue_name
      old_pid = "#{server.config[:pid]}.oldbin"
      if old_pid != server.pid
        sleep sleep_secs
        begin
          sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
          Process.kill(sig, File.read(old_pid).to_i)

          mq = ::Uc::Mqueue.new(queue_name)
          writer = mq.nb_writer
          writer.send("started worker #{worker.nr + 1}")
          if sig == :QUIT
            writer.send("fin")
          end
        rescue Errno::ENOENT, Errno::ESRCH, Errno::EAGAIN => e
        end
     end
    end

    def self.clean_env
      ENV.delete "BUNDLE_BIN_PATH"
      ENV.delete "RUBYLIB"
      ENV.delete "RUBYOPT"
      ENV.delete "GEM_HOME"
      ENV.delete "GEM_PATH"
    end


    def self.get_queue_name
      queue_name = queue_name_from_file
      queue_name ||= "unicorn_#{Process.uid}"
      return queue_name
    end

    def self.queue_name_from_file
      queue_file = Pathname.new self.queue_file
      queue_name = nil
      if queue_file.readable?
        queue_name = File.read(queue_file).chomp
        queue_name = (queue_name.empty? ? nil : queue_name)
      end
      return queue_name
    end

    def self.pre_start(server, worker, url: "/")
      app = server.instance_variable_get("@app")
      response = app.call(rack_request(url))
      body = response[2]
      body.close
    rescue => e
      puts "WARN: pre start url failed : #{e.message}"
    end

    private

    def self.rack_request(url)
      Rack::MockRequest.env_for("http://127.0.0.1/#{url}")
    end

  end
end
