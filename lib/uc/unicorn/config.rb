require 'uc/logger'
require 'uc/error'
require 'erb'

module Uc
  module Unicorn

    class Config

      include ::Uc::Logger  

      attr_reader :paths, :config

      def initialize(config_hash, paths)
        @config = config_hash
        @paths = paths
      end

      def path
        generate_once
        paths.unicorn_config
      end

      def generate_config_file
        erb = ERB.new(File.read(paths.unicorn_template))
        binding = Kernel.binding
        File.open(paths.unicorn_config, 'w') do |f|
          f.write erb.result(binding)
        end 
        return true
      rescue => e
        logger.debug e.message
        raise ::Uc::Error, "unable to generate unicorn config"
      end

      def generate_once
        return if @config_generated
        generate_config_file
        @config_generated = true
      end


    end

  end 
end
