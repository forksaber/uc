require 'uc/logger'
require 'uc/unicorn/helper'

module Uc
  module Unicorn
    class Prestart

      include ::Uc::Logger
      include Helper

      attr_reader :server, :worker, :url

      def initialize(server, worker, url: "/")
        @server = server
        @worker = worker
        @url = url
      end

      def app
        @app ||= server.instance_variable_get("@app")
      end

      def run
        make_prestart_request
      end

      def make_prestart_request
        event_stream.debug "prestarting worker #{id}"
        response = app.call(rack_request)
        body = response[2]
        if body.is_a? Rack::BodyProxy
          body.close
        end

        event_stream.debug "worker #{id} prestart successful"
      rescue => e
        event_stream.warn "prestart failed for worker #{id}, #{e.class}"
      end

      private

      def rack_request
        Rack::MockRequest.env_for("http://127.0.0.1/#{url}")
      end

    end
  end
end
