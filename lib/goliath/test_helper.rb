require 'em-synchrony'
require 'em-synchrony/em-http'

require 'goliath/api'
require 'goliath/server'
require 'goliath/rack'
require 'rack'

Goliath.run_app_on_exit = false

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
  #           b = MultiJson.load(c.response)
  #           b['response'].should == 'test'
  #         end
  #       end
  #     end
  #   end
  #
  module TestHelper
    DEFAULT_ERROR = Proc.new { fail "API request failed" }

    def self.included(mod)
      Goliath.env = :test
    end

    # Launches an instance of a given API server. The server
    # will launch on the specified port.
    #
    # @param api [Class] The API class to launch
    # @param port [Integer] The port to run the server on
    # @param options [Hash] The options hash to provide to the server
    # @return [Goliath::Server] The executed server
    def server(api, port, options = {}, &blk)
      op = OptionParser.new

      s = Goliath::Server.new
      s.logger = setup_logger(options)
      s.api = api.new
      s.app = Goliath::Rack::Builder.build(api, s.api)
      s.api.options_parser(op, options)
      s.options = options
      s.port = port
      s.plugins = api.plugins
      @test_server_port = s.port if blk
      s.start(&blk)
      s
    end

    def setup_logger(opts)
      return fake_logger if opts[:log_file].nil? && opts[:log_stdout].nil?

      log = Log4r::Logger.new('goliath')
      log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
      log.level = opts[:verbose].nil? ? Log4r::INFO : Log4r::DEBUG

      if opts[:log_stdout]
        log.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
      elsif opts[:log_file]
        file = opts[:log_file]
        FileUtils.mkdir_p(File.dirname(file))

       log.add(Log4r::FileOutputter.new('fileOutput', {:filename => file,
                                                       :trunc => false,
                                                       :formatter => log_format}))
      end
      log
    end

    # Stops the launched API
    #
    # @return [Nil]
    def stop
      EM.stop_event_loop
    end

    # Wrapper for launching API and executing given code block. This
    # will start the EventMachine reactor running.
    #
    # @param api [Class] The API class to launch
    # @param options [Hash] The options to pass to the server
    # @param blk [Proc] The code to execute after the server is launched.
    # @note This will not return until stop is called.
    def with_api(api, options = {}, &blk)
      server(api, options.delete(:port) || 9900, options, &blk)
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

    # Make a HEAD request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the HEAD request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def head_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).head(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a GET request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the GET request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def get_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).get(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a POST request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the POST request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def post_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).post(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a PUT request the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the PUT request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def put_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).put(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a PATCH request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the PUT request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def patch_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).patch(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make a DELETE request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the DELETE request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def delete_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).delete(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    # Make an OPTIONS request against the currently launched API.
    #
    # @param request_data [Hash] Any data to pass to the OPTIONS request.
    # @param errback [Proc] An error handler to attach
    # @param blk [Proc] The callback block to execute
    def options_request(request_data = {}, errback = DEFAULT_ERROR, &blk)
      req = create_test_request(request_data).options(request_data)
      hookup_request_callbacks(req, errback, &blk)
    end

    def create_test_request(request_data)
      domain = request_data.delete(:domain) || "localhost:#{@test_server_port}"
      path = request_data.delete(:path) || ''
      opts = request_data.delete(:connection_options) || {}

      EM::HttpRequest.new("http://#{domain}#{path}", opts)
    end

    private

    def fake_logger
      Class.new do
        def method_missing(name, *args, &blk)
          nil
        end
      end.new
    end
  end
end
