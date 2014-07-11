require 'uc/shell_helper'

module Uc
  class Status

    include ::Uc::ShellHelper

    attr_reader :paths
    attr_accessor :use_pid

    def initialize(unicorn_paths)
      @paths =  unicorn_paths
      @use_pid = true
    end

    def running?
      return process_running? pid if use_pid
      not ex_lock_available?
    end

    def pid
      @pid ||= read_pid
    end

    def stopped?
      not running?
    end

    def to_s
      status = ( running? ? "Running pid #{pid}" : "Stopped")
    end

    private

    def ex_lock_available?
      File.open( paths.lock_file, 'a+') do |f|
        ex_lock = f.flock(File::LOCK_EX|File::LOCK_NB)
      end
    end

    def read_pid
      puts paths.pid_file
      pid = (File.read paths.pid_file).to_i
      pid == 0 ? -1 : pid
    rescue
      return -1
    end


  end
end
