require 'uc/logger'
require 'uc/shell_helper'
require 'uc/mqueue'
require 'uc/unicorn/api'
require 'uc/unicorn/config'
require 'uc/error'

module Uc

  class Server

    include ::Uc::ShellHelper
    include ::Uc::Logger

    attr_reader :uconfig
    attr_reader :rails_env

    def initialize(app_dir, rails_env: "production")
      @uconfig = ::Uc::Unicorn::Config.new(app_dir)
      @rails_env = rails_env
      @uconfig.load_env
    end

    def app_env(&block)
      uconfig.dirs_checked? || uconfig.check_dirs
      yield if block
    end

    def start 
      app_env do
        if server_running?
          logger.info "unicorn already running pid #{pid}"
          return
        end

        cmd %{unicorn -c #{uconfig.config_path} -D -E #{rails_env} }, return_output: false,
          error_msg: "error starting unicorn"
      end
    end

    def stop
      app_env do
        if not server_running?
          puts "unicorn not running"
          return
        end

        kill(pid, 30)
      end
    end

    def status
      status = ( server_running? ? "Running pid #{pid}" : "Stopped")  
      puts status
    end

    def restart
      stop
      start
    end

    def rolling_restart
      app_env
      if not server_running?
        start
        return
      end
      mq = ::Uc::Mqueue.new(queue_name)
      begin
        mq.watch :fin do
          Process.kill("USR2", pid)
        end
      rescue Errno::EACCES
        raise ::Uc::Error, "unable to setup message queue"
      rescue Errno::ENOENT
        raise ::Uc::Error, "message queue deleted"
      rescue Errno::ETIMEDOUT
        raise ::Uc::Error, "timeout reached while waiting for server to restart"
      end
    end

    private

    def kill(pid, timeout)
      Process.kill(:TERM, pid)
      logger.debug "TERM signal sent to #{pid}"
      (1..timeout).each do
        if not process_running? pid
          logger.info "Stopped #{pid}"
          return
        end
        sleep 1
      end
      Process.kill(9, pid)
      sleep 1
      logger.info "Killed #{pid}"
    end


    def process_running?(pid)
      return false if pid <= 0
      Process.getpgid pid
      return true
    rescue Errno::ESRCH
        return false
    end

    def server_running?
      process_running? pid
    end

    def pid
      uconfig.pid
    end

    def queue_name
      @queue_name ||= Dir.chdir uconfig.app_dir do
        api = ::Uc::Unicorn::Api.new
        api.queue_name
      end
    end

  end
end
