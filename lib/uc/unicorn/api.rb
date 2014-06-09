require 'uc/unicorn/rolling_restart'
require 'uc/unicorn/prestart'
require 'securerandom'

module Uc; module Unicorn
 
  class Api

    attr_reader :run_id

    def initialize
      @run_id = SecureRandom.hex(3)
    end

    def rolling_restart(server, worker, **kwargs)
      rolling_restart = ::Uc::Unicorn::RollingRestart.new(server, worker, queue_name, **kwargs)
      rolling_restart.run_id = @run_id
      rolling_restart.run
    end


    def prestart(server, worker, **kwargs)
      prestart = ::Uc::Unicorn::Prestart.new(server, worker, queue_name, **kwargs)
      prestart.run_id = @run_id
      prestart.run
    end

    def clean_env
      ENV.delete "BUNDLE_BIN_PATH"
      ENV.delete "RUBYLIB"
      ENV.delete "RUBYOPT"
      ENV.delete "GEM_HOME"
      ENV.delete "GEM_PATH"
    end

    def queue_name
      @queue_name ||= begin
        queue_name_from_file || "unicorn_#{Process.uid}"
      end
    end

    private 

    def queue_name_from_file
      queue_file = Pathname.new queue_name_file
      queue_name = nil
      if queue_file.readable?
        queue_name = File.read(queue_file).chomp
        queue_name = (queue_name.empty? ? nil : queue_name)
      end
      return queue_name
    end

    def queue_name_file
      "config/unicorn_mq"  
    end

  end

end; end
