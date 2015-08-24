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
    attr_accessor :use_pid

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
      if config[:instances] == 0
        puts "wont start 0 instances"
        return
      end
      ENV["UNICORN_APP_DIR"] = config[:working_dir]
      event_stream.expect :fin do
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
      paths.validate_required
      Dir.chdir app_dir
      puts server_status
    end

    def restart
      stop
      start
    end

    def rolling_restart
      init_once
      if config[:instances] == 0
        puts "0 instances specified: stopping"
        stop if server_status.running?
        return
      end
      uconfig.generate_once
      if not server_status.running?
        start
        return
      end
      event_stream.expect :fin do
        Process.kill("USR2", server_status.pid)
      end
    end

    def print_config
      init_once
      config.each do |k,v| 
        v = %{ "#{v}" } if not v.is_a? Numeric
        puts "#{k} #{v}" 
      end
    end

    def reopen_logs
      init_once
      return if not server_status.running?
      Process.kill(:USR1 , server_status.pid)
      puts "reopened logs"
    end

    private

    def server_status
      @server_status ||= ::Uc::Status.new(unicorn_paths, use_pid: use_pid)
    end

    def paths
      @paths ||= ::Uc::Paths.new(app_dir)
    end

    def config
      @config ||= ::Uc::Config.new(app_dir).to_h
    end

    def unicorn_paths
      @unicorn_paths ||= ::Uc::Unicorn::Paths.new(config[:working_dir])
    end

    def uconfig
      @uconfig ||= ::Uc::Unicorn::Config.new(config, unicorn_paths)
    end

    def lock
      @lock ||= ::Uc::Lock.new(app_dir)
    end

    def init
      paths.validate_required
      Dir.chdir app_dir
      lock.acquire
      ::Uc::Logger.event_queue = config[:event_queue]
      event_stream.debug_output = true if @debug
    end

    def init_once
      @init_once ||= begin
        init
        true
      end
    end

  end   
end
