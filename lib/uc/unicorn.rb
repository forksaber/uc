require 'uc/mqueue'
module Uc
  module Unicorn

    def self.rolling_restart(server, worker, queue_name, sleep_secs: 1)
      old_pid = "#{server.config[:pid]}.oldbin"
      if old_pid != server.pid
        begin
          sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
          Process.kill(sig, File.read(old_pid).to_i)

          mq = ::Uc::Mqueue.new(queue_name)
          writer = mq.nb_writer
          writer.send("started worker #{worker.nr}")
          if sig == :QUIT
            writer.send("fin")
          end
          sleep sleep_secs
        rescue Errno::ENOENT, Errno::ESRCH, Errno::EAGAIN => e
          puts "#{e.message}"
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


  end
end
