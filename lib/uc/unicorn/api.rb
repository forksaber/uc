require 'uc/config'
require 'uc/unicorn/init'
require 'uc/unicorn/gradual_shutdown'
require 'uc/unicorn/prestart'
require 'uc/unicorn/ready_event'
require 'uc/unicorn/ready_wait'
require 'securerandom'
require 'uc/logger'

module Uc; module Unicorn
 
  class Api

    attr_reader :run_id, :original_env
    attr_accessor :queue_name

    def initialize(event_queue)
      @queue_name = event_queue
      @run_id = SecureRandom.hex(3)
      ::Uc::Logger.event_queue = queue_name
    end
    
    def init(server)
      @init ||= ::Uc::Unicorn::Init.new(server)
      @init.run_once
    end

    def gradual_shutdown(server, worker)
      gradual_shutdown = ::Uc::Unicorn::GradualShutdown.new(server, worker)
      gradual_shutdown.run
    end

    def prestart(server, worker, **kwargs)
      prestart = ::Uc::Unicorn::Prestart.new(server, worker, **kwargs)
      prestart.run
    end

    def send_worker_ready(server, worker, **kwargs)
      ready_event = ::Uc::Unicorn::ReadyEvent.new(server, worker, **kwargs)
      ready_event.run_id = run_id
      ready_event.run
    end

    def wait_for_worker_ready(server, worker, **kwargs)
      ready_event_wait = ::Uc::Unicorn::ReadyWait.new(server, worker, **kwargs)
      ready_event_wait.run_id = run_id
      ready_event_wait.run
    end

    def acquire_shared_lock(lock_file)
      shared_lock = ::Uc::Unicorn::Lock.new(lock_file)
      shared_lock.acquire
    end

    def oom_adjust
      pid = Process.pid
      oom_file = "/proc/#{pid}/oom_score_adj"
      File.open(oom_file,"w") do |f|
        f.write "800"
      end
    end

    def shared_env
      @shared_env ||= {}
    end

    def end_run(worker)
      @init.end_run(worker)
    end

    def on_exec_fail
      event_stream = ::Uc::Logger.event_stream
      event_stream.close_connections
      event_stream.fatal "re-exec failed"
    end

    def clean_env
      return if not File.exist? ".clean_env"
      ENV.delete "BUNDLE_BIN_PATH"
      ENV.delete "RUBYLIB"
      ENV.delete "RUBYOPT"
      ENV.delete "GEM_HOME"
      ENV.delete "GEM_PATH"
      ENV.delete "BUNDLE_GEMFILE"
      ENV["PATH"] = cleaned_path
    end

    def load_env
      config = ::Uc::Config.new(Dir.pwd)
      config.load_env
    end

    def cleaned_path
      paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
      paths.reject! { |x| x =~ /vendor\/bundle\/ruby/ }
      paths.uniq.join(File::PATH_SEPARATOR)
    end

    def load_original_env
      return if not @original_env.is_a? Hash
      ENV.select { |k,v| k =~ /\AUNICORN_/ }.each { |k,v| @original_env[k] = v }
      ENV.replace(@original_env)
    end

    def init_original_env
      return if @original_env
      @original_env = ENV.to_h
    end

  end

end; end
