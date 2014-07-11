require 'pathname'
require 'uc/logger'

module Uc
  class Paths

    include ::Uc::Logger  

    attr_reader :app_dir

    def initialize(app_dir)
      @app_dir = Pathname.new(app_dir )
    end

    def config
      rpath "config/uc.rb"
    end

    def rack
      rpath "config.ru"
    end

    def log_dir
      rpath "log"
    end

    def tmp_dir
      rpath "tmp"
    end

    def socket_dir
      rpath "tmp/sockets"
    end

    def pid_dir
      rpath "tmp/pids"
    end

    def validate_required
      errors = []
      required_dirs = [ app_dir, tmp_dir, log_dir, socket_dir, pid_dir ]
      
      required_dirs.each do |d|
        path = Pathname.new d
        rel_path = path.relative_path_from(app_dir)
        if not path.exist?
          errors << "directory doesn't exist => #{rel_path}"
          next
        end
        if not path.directory?
          errors << "path not a directory => #{rel_path}"
          next
        end
        if not path.writable?
          errors << "directory not writable => #{rel_path}"
        end
      end

      rack_path = Pathname.new self.rack
      if not rack_path.readable?
        errors << "no config.ru found in app_dir root"
      end

      if not errors.empty?
       errors.each { |e| logger.error e }
        raise ::Uc::Error, "exiting due to missing dirs/files" 
      end
    end
    
    private

    def dir_writable?(path_str)
      path = Pathname.new(path_str)
      path.writable? and path.directory?
    end

    def rpath(path)
      path = Pathname.new(path)
      raise "absolute path specified: #{path}" if path.absolute?
      "#{app_dir}/#{path}"
    end

    def path_readable?(path_str)
      path = Pathname.new(path_str)
      path.readable?
    end

  end
end
