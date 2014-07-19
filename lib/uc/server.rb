require 'uc/logger'
require 'uc/shell_helper'
require 'uc/config'
require 'uc/status'
require 'uc/unicorn/config'
require 'uc/unicorn/paths'
require 'uc/error'
require 'uc/paths'

module Uc
  class Server

    include ::Uc::ShellHelper
    include ::Uc::Logger

    attr_reader :paths, :rails_env, :app_dir

    def initialize(app_dir, rails_env: "production", debug: false)
      @app_dir = app_dir
      @rails_env = rails_env
      @debug = debug
    end

    def start 
      init_once
      if server_status.running?
        puts server_status
        return
      end
      event_stream.watch_in_background :fin do
        cmd %{unicorn -c #{uconfig.path} -D -E #{rails_env} }, return_output: false,
          error_msg: "error starting unicorn"
      end
    end

    def stop
      init_once
      if server_status.stopped?
        logger.info "unicorn not running"
        return
      end
      kill(server_status.pid, 30)
    end

    def status
      puts server_status
    end

    def restart
      stop
      start
    end

    def rolling_restart
      init_once
      uconfig.generate_once
      if not server_status.running?
        start
        return
      end
      event_stream.watch :fin do
        Process.kill("USR2", server_status.pid)
      end
    end

    def print_config
      init_once
      config.to_h.each { |k,v| puts "#{k} #{v}" }
    end

    private

    def server_status
      @server_status ||= ::Uc::Status.new(unicorn_paths)
    end

    def paths
      @paths ||= ::Uc::Paths.new(app_dir)
    end

    def config
      @config ||= ::Uc::Config.new(app_dir)
    end

    def unicorn_paths
      @unicorn_paths ||= ::Uc::Unicorn::Paths.new(config.app_dir)
    end

    def uconfig
      @uconfig ||= ::Uc::Unicorn::Config.new(config.to_h, unicorn_paths)
    end

    def lock
      @lock ||= ::Uc::Lock.new(app_dir)
    end

    def init
      paths.validate_required
      lock.acquire
      ::Uc::Logger.event_queue = config.event_queue_name
      config.load_env
      event_stream.debug_output = true if @debug
    end

    def init_once
      @init_once ||= init
    end

  end   
end
