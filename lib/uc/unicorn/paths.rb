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
        abs_path "log/unicorn.stdout.log"
      end

      def stderr_log
        abs_path "log/unicorn.stderr.log"
      end

      def socket
        abs_path "tmp/sockets/unicorn.sock"
      end

      def pid_file
        abs_path "tmp/pids/unicorn.pid"
      end

      def lock_file
        abs_path "tmp/unicorn.lock"
      end

      def unicorn_config
        abs_path "tmp/unicorn_config.rb"
      end

      def unicorn_template
        "#{__dir__}/../templates/unicorn.erb"
      end

      private

     def abs_path(path)
      "#{app_dir}/#{path}"
     end

    end
  end
end
