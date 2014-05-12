require 'pathname'
require 'uc/logger'
require 'uc/shell_helper'
require 'uc/mqueue'
require 'uc/error'

module Uc
  class Server

    include ::Uc::ShellHelper
    include ::Uc::Logger

    attr_reader :app_dir

    def initialize(app_dir)
      @app_dir = Pathname.new(app_dir)
    end

    def app_env(&block)
      dirs_checked? || check_dirs
      yield if block
    end

    def start 
      app_env do
        if server_running?
          logger.info "unicorn already running pid #{pid}"
          return
        end

        cmd %{unicorn -c #{config_path} -D}, return_output: false,
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
      Process.kill(15, pid)
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
      raise ::Uc::Error, "argument missing mq name"  if (queue.nil? || queue.empty?)
      mq = ::Uc::Mqueue.new(queue)
      mq.watch do
        Process.kill("USR2", pid)
      end
    end

    def process_running?(pid)
      return false if pid <= 0

      running = Process.kill(0, pid)
      running == 1 ? true : false
    rescue Errno::ESRCH
        return false
    end

    def server_running?
      process_running? pid
    end

    def config_path
      @config_path ||= rpath("config/unicorn.rb")
    end

    def rack_path
      rpath("config.ru")
    end

    def pid_file
      @pid_file ||= rpath("tmp/pids/unicorn.pid")
    end

    def read_pid
      (File.read pid_file).to_i rescue 0
    end

    def pid
      @pid ||= read_pid
    end

    def check_dirs
      logger.debug "Using app_dir => #{app_dir}"
      raise ::Uc::Error, %{app_dir not readable} if not app_dir.readable?
      Dir.chdir app_dir do
        raise ::Uc::Error, %{no config.ru found in app_dir} if not rack_path.readable?
        raise ::Uc::Error, %{no unicorn config found %} if not config_path.readable?
      end
      @dirs_checked = true
    end

    def rpath(path)
      path = Pathname.new(path)
      raise "absolute path specified: #{path}" if path.absolute?
      app_dir + path
    end

    def dirs_checked?
      @dirs_checked
    end


  end
end
