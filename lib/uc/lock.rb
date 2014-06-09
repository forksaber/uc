require 'uc/error'
module Uc
  class Lock

    attr_reader :app_dir
    def initialize(app_dir)
      @app_dir = app_dir
    end

    def acquire
      Dir.chdir app_dir do
        lock_acquired = File.new("tmp/.uc.lock", "a+").flock( File::LOCK_NB | File::LOCK_EX )
        raise ::Uc::Error,"another uc process is already running"  if not lock_acquired
      end
    end

  end
end
