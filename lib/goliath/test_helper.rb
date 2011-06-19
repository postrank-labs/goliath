require 'em-synchrony'
require 'em-synchrony/em-http'

require 'goliath/server'
require 'goliath/rack/builder'
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
      Goliath.env = :test
    end

    # Launches an instance of a given API server. The server
    # will launch on the default settings of localhost port 9000.
    #
    # @param api [Class] The API class to launch
    # @param port [Integer] The port to run the server on
    # @param options [Hash] The options hash to provide to the server
    # @return [Goliath::Server] The executed server
    def server(api, port = 9000, options = {}, &blk)
      op = OptionParser.new

      s = Goliath::Server.new
      s.logger = mock('log').as_null_object
      s.api = api.new
      s.app = Goliath::Rack::Builder.build(api, s.api)
      s.api.options_parser(op, options)
      s.options = options
      s.port = port
      s.start(&blk)
      s
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
    # @param options [Hash] The options to pass to the server
    # @param blk [Proc] The code to execute after the server is launched.
    # @note This will not return until stop is called.
    def with_api(api, options = {}, &blk)
      server(api, 9000, options, &blk)
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

    # Make a HEAD request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the HEAD request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def head_request(request_data = {}, errback = nil, &blk)
      path = request_data.delete(:path) || ''
      req = EM::HttpRequest.new("http://localhost:9000#{path}").head(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a GET request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the GET request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def get_request(request_data = {}, errback = nil, &blk)
      path = request_data.delete(:path) || ''
      req = EM::HttpRequest.new("http://localhost:9000#{path}").get(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a POST request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the POST request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def post_request(request_data = {}, errback = nil, &blk)
      path = request_data.delete(:path) || ''
      req = EM::HttpRequest.new("http://localhost:9000#{path}").post(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a PUT request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the PUT request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def put_request(request_data = {}, errback = nil, &blk)
      path = request_data.delete(:path) || ''
      req = EM::HttpRequest.new("http://localhost:9000#{path}").put(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end
  end
end
