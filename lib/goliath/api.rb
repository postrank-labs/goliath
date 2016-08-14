require 'goliath/goliath'
require 'goliath/response'
require 'goliath/request'
require 'goliath/rack'
require 'goliath/validation'

module Goliath
  # All Goliath APIs subclass Goliath::API. All subclasses _must_ override the
  # {#response} method.
  #
  # @example
  #  require 'goliath'
  #
  #  class HelloWorld < Goliath::API
  #    def response(env)
  #      [200, {}, "hello world"]
  #    end
  #  end
  #
  class API
    include Goliath::Constants
    include Goliath::Rack::Validator

    class << self
      # Catches the userland class which inherits the Goliath API
      #
      # In case of further subclassing, the very last class encountered is used.
      def inherited(subclass)
        Goliath::Application.app_class = subclass.name if defined?(Goliath::Application)
      end

      # Retrieves the middlewares defined by this API server
      #
      # @return [Array] array contains [middleware class, args, block]
      def middlewares
        @middlewares ||= []

        unless @loaded_default_middlewares
          @middlewares.unshift([::Goliath::Rack::DefaultResponseFormat, nil, nil])
          @middlewares.unshift([::AsyncRack::ContentLength, nil, nil])

          if Goliath.env?(:development) && !@middlewares.detect {|mw| mw.first == ::Rack::Reloader}
            @middlewares.unshift([::Rack::Reloader, 0, nil])
          end

          @loaded_default_middlewares = true
        end

        @middlewares
      end

      # Specify a middleware to be used by the API
      #
      # @example
      #  use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}
      #
      #  use ::Rack::Rewrite do
      #    rewrite %r{^(.*?)\??gziped=(.*)$}, lambda { |match, env| "#{match[1]}?echo=#{match[2]}" }
      #  end
      #
      # @param name [Class] The middleware class to use
      # @param args Any arguments to pass to the middeware
      # @param block A block to pass to the middleware
      def use(name, *args, &block)
        @middlewares ||= []

        if name == Goliath::Rack::Render
          [args].flatten.each do |type|
            type = Goliath::Rack::Formatters.const_get type.upcase
            @middlewares << [type, nil, nil]
          end
        end

        @middlewares << [name, args, block]
        @middlewares = @middlewares.uniq
      end

      # Returns the plugins configured for this API
      #
      # @return [Array] array contains [plugin name, args]
      def plugins
        @plugins ||= []
      end

      # Specify a plugin to be used by the API
      #
      # @example
      #  plugin Goliath::Plugin::Latency
      #
      # @param name [Class] The plugin class to use
      # @param args The arguments to the plugin
      def plugin(name, *args)
        plugins.push([name, args])
      end
    end

    ##
    # The default constructor does nothing with the options
    # passed, redefine your own to use them.
    #
    # @param [Hash] opts options passed to a map call if any
    #
    def initialize(opts = {})
      @opts = opts
    end

    # Default stub method to add options into the option parser.
    #
    # @example
    #  def options_parser(opts, options)
    #    options[:test] = 0
    #    opts.on('-t', '--test NUM', "The test number") { |val| options[:test] = val.to_i }
    #  end
    #
    # @param opts [OptionParser] The options parser
    # @param options [Hash] The hash to insert the parsed options into
    def options_parser(opts, options)
    end

    # Accessor for the current env object
    #
    # @note This will not work in a streaming server. You must pass around the env object.
    #
    # @return [Goliath::Env] The current environment data for the request
    def env
      Thread.current[GOLIATH_ENV]
    end

    # The API will proxy missing calls to the env object if possible.
    #
    # The two entries in this example are equivalent as long as you are not
    # in a streaming server.
    #
    # @example
    #   logger.info "Hello"
    #   env.logger.info "Hello"

    def method_missing(name, *args, &blk)
      name = name.to_s
      if env.respond_to?(name)
        env.send(name, *args, &blk)
      else
        super(name.to_sym, *args, &blk)
      end
    end

    # @param name [Symbol] The method to check if we respond to it.
    # @return [Boolean] True if the API's method_missing responds to the method
    def respond_to_missing?(name, *)
      env.respond_to? name
    end

    # {#call} is executed automatically by the middleware chain and will setup
    # the environment for the {#response} method to execute. This includes setting
    # up a new Fiber, handing any exceptions thrown from the API and executing
    # the appropriate callback method for the API.
    #
    # @param env [Goliath::Env] The request environment
    # @return [Goliath::Connection::AsyncResponse] An async response.
    def call(env)
      begin
        Thread.current[GOLIATH_ENV] = env
        status, headers, body = response(env)

        if status
          if body == Goliath::Response::STREAMING
            env[STREAM_START].call(status, headers)
          else
            env[ASYNC_CALLBACK].call([status, headers, body])
          end
        end

      rescue Goliath::Validation::Error => e
        env[RACK_EXCEPTION] = e
        env[ASYNC_CALLBACK].call(validation_error(e.status_code, e.message, e.headers))

      rescue Exception => e
        logthis = "#{e.backtrace[0]}: #{e.message} (#{e.class})\n"
        e.backtrace[1..-1].each do |bt|
          logthis += "    from #{bt}\n"
        end
        env.logger.error(logthis)
        env[RACK_EXCEPTION] = e

        message = Goliath.env?(:production) ? 'An error happened' : e.message
        env[ASYNC_CALLBACK].call(validation_error(500, message))
      end

      Goliath::Connection::AsyncResponse
    end

    # Response is the main implementation method for Goliath APIs. All APIs
    # should override this method in order to do any actual work.
    #
    # The response method will be executed in a new Fiber and wrapped in a
    # begin rescue block to handle an thrown API errors.
    #
    # @param env [Goliath::Env] The request environment
    # @return [Array] Array contains [Status code, Headers Hash, Body]
    def response(env)
      env.logger.error('You need to implement response')
      raise Goliath::Validation::InternalServerError.new('No response implemented')
    end

    # Helper method for streaming response apis.
    #
    # @param status_code [Integer] The status code to return (200 by default).
    # @param headers [Hash] Headers to return.
    def streaming_response(status_code = 200, headers = {})
      [status_code, headers, Goliath::Response::STREAMING]
    end

    # Helper method for chunked transfer streaming response apis
    #
    # Chunked transfer streaming is transparent to all clients (it's just as
    # good as a normal response), but allows an aware client to begin consuming
    # the stream even as it's produced.
    #
    # * http://en.wikipedia.org/wiki/Chunked_transfer_encoding
    # * http://developers.sun.com/mobility/midp/questions/chunking/
    # * http://blog.port80software.com/2006/11/08/
    #
    # @param status_code [Integer] The status code to return.
    # @param headers [Hash] Headers to return. The Transfer-Encoding=chunked
    #   header is set for you.
    #
    # If you are using chunked streaming, you must use
    # env.chunked_stream_send and env.chunked_stream_close
    def chunked_streaming_response(status_code = 200, headers = {})
      streaming_response(status_code, headers.merge(Goliath::Response::CHUNKED_STREAM_HEADERS))
    end
  end
end
