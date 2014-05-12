require 'pathname'
require 'uc/logger'
module Uc
  class UnicornConfig

    include ::Uc::Logger  

    attr_reader :app_dir

    def initialize(app_dir)
      @app_dir = app_dir
    end

    def config_path
      rpath "config/unicorn.rb"
    end


    def stdout_log
      rpath "log/unicorn.stdout_log"
    end

    def stderr_log
      rpath "log/unicorn.stderr_log"
    end

    def socket_file
      rpath "tmp/sockets/unicorn.sock"
    end

    def pid_file
      rpath "tmp/pids/unicorn.pid"
    end

    def rack_path
      rpath "config.ru"
    end

    def read_pid
      pid = (File.read pid_file).to_i
      pid == 0 ? -1 : pid
    rescue
      return -1
    end

    def check_dirs
      logger.debug "Using app_dir => #{app_dir}"
      raise ::Uc::Error, %{app_dir not readable} if not path_readable? app_dir
      Dir.chdir app_dir do
        raise ::Uc::Error, %{no config.ru found in app_dir} if not path_readable? rack_path
        raise ::Uc::Error, %{no unicorn config found %} if not path_readable? config_path
      end
      @dirs_checked = true
    end
  
    def dirs_checked?
      @dirs_checked
    end


    private 

    def rpath(path)
      path = Pathname.new(path)
      raise "absolute path specified: #{path}" if path.absolute?
      "#{app_dir}/#{path}"
    end

    def rpathname(path)
      Pathname.new(rpath(path))
    end
  
    def path_readable?(path_str)
      path = Pathname.new(path_str)
      path.readable?
    end

  end
end
