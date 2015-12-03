require 'uc/logger'
require 'uc/error'
require 'yaml'

module Uc
  class Config

    include Logger

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
      load_env_yml "#{app_dir}/config/env.yml"
      load_env_yml "#{app_dir}/.env.yml"
      read_from_file "#{app_dir}/config/uc.custom.rb"
      read_from_file config_file
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

    def env_yml(path, required: true)
      load_env_yml(path, required: required)
    end

    def load_env
      # all environment variables will be loaded on config parsing
      config
    end

    def after_fork(&block)
      config[:after_fork] = block
    end

    def load_env_yml(path, required: false)
      if not File.readable? path
        raise Error, "env file #{path} unreadable" if required
        logger.debug "skipped loading env from #{path}"
        return {}
      end
      logger.debug "loading env from #{path}"
      h = YAML.load_file(path)
      h.each { |k,v| ENV[k] = v.to_s }
    rescue => e
      raise Error, "failed to load env from #{path} : #{e.message}" if required
      logger.debug "failed to load env from #{path} : #{e.message}"
    end

    def read_from_file(file)
      return if not File.readable? file
      instance_eval(File.read(file))
    rescue NoMethodError => e
      logger.warn "invalid option used in config: #{e.name}"
    end

  end
end
