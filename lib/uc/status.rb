require 'uc/shell_helper'
require 'uc/logger'

module Uc
  class Status

    include ::Uc::ShellHelper
    include ::Uc::Logger

    attr_reader :paths
    attr_accessor :use_pid

    def initialize(unicorn_paths, use_pid: false)
      @paths =  unicorn_paths
      @use_pid = use_pid
    end

    def running?
      return process_running? pid if use_pid
      not ex_lock_available?
    end

    def pid
      pid = pid_from_file
      if pid_valid?
        return pid
      else
        logger.debug "pids holding unicorn.lock => #{fuser_pids.join(' ')}"
        logger.debug "pid from file => #{pid}"
        raise ::Uc::Error, "stale pid #{pid}"
      end
    end

    def pid_from_file
      @pid_from_file ||= read_pid
    end

    def stopped?
      not running?
    end

    def to_s
      status = ( running? ? "Running pid #{pid}" : "Stopped" )
    end
      
    private

    def ex_lock_available?
      File.open( paths.lock_file, 'a+') do |f|
        ex_lock = f.flock(File::LOCK_EX|File::LOCK_NB)
      end
    end

    def read_pid
      pid = (File.read paths.pid_file).to_i
      pid == 0 ? -1 : pid
    rescue
      return -1
    end

    def fuser_pids
      @fuser_pids ||= begin
        output = `#{fuser} #{paths.lock_file} 2>/dev/null`
        pids = output.strip.split.map { |pid| pid.to_i }
      end
    end

    def pid_valid?
      if use_pid
        return true
      else
        fuser_pids.include?(pid_from_file)
      end
    end

    def fuser
      if File.exists? "/usr/sbin/fuser"
        return "/usr/sbin/fuser"
      else
        return "fuser"
      end
    end

  end
end
