module Uc
  class Config

    attr_reader :config_file

    def initialize(config_file)
      @config_file = config_file
    end

    def config
      return @config if @config
      @config = {
        instances: 2,
        queue_size: 128,
        timeout: 30,
        prestart_wait: 5,
        prestart_url: "/",
        working_dir: Dir.pwd,
        before_fork: nil
      }
      read_from_file
      return @config
    end

    def to_h
      config
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
