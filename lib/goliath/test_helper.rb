require 'em-synchrony'
require 'em-synchrony/em-http'

require 'goliath/server'
require 'rack'

module Goliath
  module TestHelper
    def build_app(klass)
      ::Rack::Builder.new do
        klass.middlewares.each do |mw|
          use(*(mw[0..1].compact), &mw[2])
        end
        run klass.new
      end
    end

    def server(api)
      s = Goliath::Server.new
      s.logger = mock('log').as_null_object
      s.api = api.new
      s.app = build_app(api)
      s.start
    end

    def stop
      EM.stop
    end

    def with_api(api, &blk)
      EM.synchrony do
        server(api)
        blk.call
      end
    end

    def hookup_request_callbacks(req, &blk)
      req.callback &blk
      req.callback { stop }
      req.errback do |c|
        fail 'HTTP request failed'
        stop
      end
    end

    def get_request(request_data = {}, &blk)
      req = EM::HttpRequest.new('http://localhost:9000').get(request_data)
      hookup_request_callbacks(req, &blk)
    end

    def post_request(request_data = {}, &blk)
      req = EM::HttpRequest.new('http://localhost:9000').post(request_data)
      hookup_request_callbacks(req, &blk)
    end
  end
end
