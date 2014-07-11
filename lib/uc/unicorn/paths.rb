require 'pathname'
require 'uc/logger'

module Uc
  module Unicorn
    class Paths

      include ::Uc::Logger  

      attr_reader :app_dir

      def initialize(app_dir)
        @app_dir = app_dir 
      end

      def stdout_log
        rpath "log/unicorn.stdout.log"
      end

      def stderr_log
        rpath "log/unicorn.stderr.log"
      end

      def socket
        rpath "tmp/sockets/unicorn.sock"
      end

      def pid_file
        rpath "tmp/pids/unicorn.pid"
      end

      def lock_file
        rpath "tmp/unicorn.lock"
      end

      def unicorn_config
        rpath "tmp/unicorn_config.rb"
      end

      def unicorn_template
        "#{__dir__}/../templates/unicorn.erb"
      end

      private

     def rpath(path)
        path = Pathname.new(path)
        raise "absolute path specified: #{path}" if path.absolute?
        "#{app_dir}/#{path}"
      end



    end
  end
end
