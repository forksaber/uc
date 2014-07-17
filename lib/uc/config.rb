module Uc
  class Config

    def initialize(app_dir, config_file = nil)
      @config_file = config_file
      @app_dir = app_dir
    end

    def config_file
      @config_file ||= "#{app_dir}/config/uc.rb"
    end

    def config
      return @config if @config
      @config = {
        instances: 2,
        queue_size: 128,
        timeout: 30,
        prestart_wait: 5,
        prestart_url: "/",
        working_dir: @app_dir,
        event_queue: "unicorn_#{Process.uid}",
        before_fork: nil
      }
      read_from_file
      return @config
    end

    def to_h
      config
    end

    def event_queue_name
      config[:event_queue]
    end

    def instances(num_instances)
      config[:instances] = num_instances
    end

    def prestart_wait(wait_time)
      config[:prestart_wait] = wait_time
    end

    def backlog(queue_size)
      config[:queue_size] = queue_size
    end

    def prestart_url(url)
      config[:prestart_url] = url
    end

    def timeout(secs)
      config[:timeout] = secs
    end

    def working_dir
      config[:working_dir] = working_dir
    end

    def event_queue(event_queue)
      config[:event_queue] = event_queue
    end

    def app_dir
      config[:working_dir]
    end

    def env_hash
      @env_hash ||= {}
    end

    def env(key, value)
      env_hash[key] = value
    end
    
    def read_from_file
      return true if not File.readable? config_file
      instance_eval(File.read(config_file))
      return true
    end

  end
end