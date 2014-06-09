require 'uc/unicorn/api'
require 'uc/unicorn/config'
app_dir = "/path/to/app/dir"

uc = ::Uc::Unicorn::Api.new
uconfig = ::Uc::Unicorn::Config.new(app_dir)

worker_processes 5
working_directory app_dir
timeout 30
listen uconfig.socket_file, :backlog => 128
pid uconfig.pid_file
stdout_path uconfig.stdout_log
stderr_path uconfig.stderr_log

preload_app true

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

check_client_connection false

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  if defined?(Resque)
    Resque.redis.quit
    Rails.logger.info('Disconnected from Redis')
  end
  uc.rolling_restart(server, worker, prestart_wait: 5)
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
  uc.prestart server, worker, url: "/in"
end

before_exec do |server|
  uc.clean_env
end
