require 'uc/logger'
require 'uc/shell_helper'
require 'uc/mqueue'
require 'uc/unicorn'
require 'uc/unicorn_config'
require 'uc/error'

module Uc
  class Server

    include ::Uc::ShellHelper
    include ::Uc::Logger

    attr_reader :uconfig
    attr_reader :rails_env

    def initialize(app_dir, rails_env: "production")
      @uconfig = ::Uc::UnicornConfig.new(app_dir)
      @rails_env = rails_env
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

    def status
      status = ( server_running? ? "Running pid #{pid}" : "Stopped")  
      puts status
    end

    def restart
      stop
      start
    end

    def rolling_restart(queue = nil)
      app_env
      if not server_running?
        start
        return
      end
      queue ||= get_queue_name
      raise ::Uc::Error, "argument missing mq name"  if (queue.nil? || queue.empty?)
      mq = ::Uc::Mqueue.new(queue)
      mq.watch err_msg: "server may not have restarted successfully" do
        Process.kill("USR2", pid)
      end
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

    def get_queue_name
      Dir.chdir uconfig.app_dir do
        return ::Uc::Unicorn.get_queue_name
      end
    end

    def read_pid
      uconfig.read_pid
    end

    def pid
      @pid ||= read_pid
    end

  end
end
