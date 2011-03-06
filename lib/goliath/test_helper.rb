require 'em-synchrony'
require 'em-synchrony/em-http'

require 'goliath/server'
require 'rack'

module Goliath
  # Methods to help with testing Goliath APIs
  #
  # @example
  #   describe Echo do
  #     include Goliath::TestHelper
  #
  #     let(:err) { Proc.new { fail "API request failed" } }
  #     it 'returns the echo param' do
  #       with_api(Echo) do
  #         get_request({:query => {:echo => 'test'}}, err) do |c|
  #           b = Yajl::Parser.parse(c.response)
  #           b['response'].should == 'test'
  #         end
  #       end
  #     end
  #   end
  #
  module TestHelper
    def self.included(mod)
      Goliath.env = 'test'
    end

    # Builds the rack middleware chain for the given API
    #
    # @param klass [Class] The API class to build the middlewares for
    # @return [Object] The Rack middleware chain
    def build_app(klass)
      ::Rack::Builder.new do
        klass.middlewares.each do |mw|
          use(*(mw[0..1].compact), &mw[2])
        end
        run klass.new
      end
    end

    # Launches an instance of a given API server. The server
    # will launch on the default settings of localhost port 9000.
    #
    # @param api [Class] The API class to launch
    # @return [Nil]
    def server(api)
      s = Goliath::Server.new
      s.logger = mock('log').as_null_object
      s.api = api.new
      s.app = build_app(api)
      s.start
    end

    # Stops the launched API
    #
    # @return [Nil]
    def stop
      EM.stop
    end

    # Wrapper for launching API and executing given code block. This
    # will start the EventMachine reactor running.
    #
    # @param api [Class] The API class to launch
    # @param blk [Proc] The code to execute after the server is launched.
    # @note This will not return until stop is called.
    def with_api(api, &blk)
      EM.synchrony do
        server(api)
        blk.call
      end
    end

    # Helper method to setup common callbacks for various request methods.
    # The given err and callback handlers will be attached and a callback
    # to stop the reactor will be added.
    #
    # @param req [EM::HttpRequest] The HTTP request to augment
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback handler to attach
    # @return [Nil]
    # @api private
    def hookup_request_callbacks(req, errback, &blk)
      req.callback &blk
      req.callback { stop }

      req.errback &errback if errback
      req.errback { stop }
    end

    # Make a GET request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the GET request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def get_request(request_data = {}, errback = nil, &blk)
      req = EM::HttpRequest.new('http://localhost:9000').get(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a POST request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the POST request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def post_request(request_data = {}, errback = nil, &blk)
      req = EM::HttpRequest.new('http://localhost:9000').post(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end
  end
end
