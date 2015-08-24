require 'uc/logger'
require 'uc/error'

module Uc
  class Config

    include ::Uc::Logger

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
        queue_size: 1024,
        timeout: 30,
        prestart_url: "/",
        working_dir: @app_dir,
        event_queue: "unicorn_#{Process.uid}",
        ready_wait: 5,
        listen: []
      }
      read_from_file
      return @config
    end

    def to_h
      config
    end

    def listen(*ports)
      config[:listen] = ports
    end

    def ready_wait(wait_timeout)
      config[:ready_wait] = wait_timeout.to_i
    end

    def event_queue_name
      config[:event_queue]
    end

    def instances(num_instances)
      config[:instances] = num_instances
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

    def working_dir(working_dir)
      config[:working_dir] = working_dir
    end

    def event_queue(event_queue)
      config[:event_queue] = event_queue
    end

    def app_dir
      config[:working_dir]
    end

    def skip_clean_env(value)
      config[:skip_clean_env] = value
    end

    def env_hash
      @env_hash ||= {}
    end

    def env(key, value)
      env_hash[key] = value
    end

    def env_yml(path, safe: false)
      @skip_autoload = true
      load_env_yml path, safe: safe
    end

    def load_env
      config
      if not @skip_autoload
        load_env_yml "#{app_dir}/config/env.yml", safe: true, override: false
      end
      env_hash.each do |k,v|
        ENV[k] = v.to_s
      end
    end


    def load_env_yml(path, safe: false, override: true)
      if not File.readable? path
        logger.debug "skipped loading env from #{path}"
      end
      require 'yaml'
      h = YAML.load_file(path)
      env_hash.merge!(h) do |key, v1, v2|
        override ? v2 : v1
      end
      logger.debug "loaded env from #{path}"
    rescue => e
      error_message = "failed to load env from #{path}: #{e.message}"
      if not safe
        raise ::Uc::Error, error_message
      else
        logger.debug error_message
      end
    end

    def read_from_file
      return if not File.readable? config_file
      instance_eval(File.read(config_file))
    rescue NoMethodError => e
      logger.warn "invalid option used in config: #{e.name}"
    end

  end
end
