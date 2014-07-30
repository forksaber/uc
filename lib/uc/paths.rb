require 'pathname'
require 'uc/logger'

module Uc
  class Paths

    include ::Uc::Logger  

    attr_reader :app_dir

    def initialize(app_dir)
      @app_dir = Pathname.new(app_dir )
    end

    def rack
      absolute_path "config.ru"
    end

    def log_dir
      absolute_path "log"
    end

    def tmp_dir
      absolute_path "tmp"
    end

    def socket_dir
      absolute_path "tmp/sockets"
    end

    def pid_dir
      absolute_path "tmp/pids"
    end

    def errors
      @errors ||= []
    end

    def validate_required
      validate_required_dirs
      verify_readable rack
      log_and_raise_errors
    end

    private

    def log_and_raise_errors
      if not errors.empty?
        errors.each { |e| logger.debug e }
        raise ::Uc::Error, "#{errors.first}"
      end
    end

    def required_dirs
      [ app_dir, tmp_dir, log_dir, socket_dir, pid_dir ]
    end

    def validate_required_dirs
      required_dirs.each do |d|
        validate_dir(d)
      end
    end

    def throw_error(type, path)
      rel_path = rpath(path)
      case type
      when :not_exist
        msg = "path doesn't exist => #{rel_path}"
      when :not_writable
        msg = "path not writable => #{rel_path}"
      when :not_dir
        msg = "path not a directory => #{rel_path}"
      end
      throw :error, msg
    end

    def validate_dir(dir)
      relative_path = rpath(dir)
      error = catch(:error) do
        throw_error :not_exist, dir if not File.exist? dir
        throw_error :not_writable, dir if not File.writable? dir
        throw_error :not_dir, dir if not File.directory? dir
      end
      errors << error if error
    end
    
    def verify_readable(path)
      relative_path = rpath(path)
      if not File.readable? path
        errors << "path not readable => #{relative_path}"
        return false
      else
        return true
      end
    end
  
    def absolute_path(path)
      path = Pathname.new(path)
      raise "absolute path specified: #{path}" if path.absolute?
      "#{app_dir}/#{path}"
    end

    def rpath(abs_path)
      path = Pathname.new abs_path
      rel_path = path.relative_path_from(app_dir)
    end

  end
end
