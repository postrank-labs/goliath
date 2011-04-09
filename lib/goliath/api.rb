require 'goliath/response'
require 'goliath/request'

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
    class << self
      # Retrieves the middlewares defined by this API server
      #
      # @return [Array] array contains [middleware class, args, block]
      def middlewares
        @middlewares ||= [[::Rack::ContentLength, nil, nil],
                          [Goliath::Rack::DefaultResponseFormat, nil, nil]]

        if Goliath.dev? && @middlewares.first[0] != ::Rack::Reloader
          # We're doing a chdir into the app directory so that we're in the same
          # place as the config. This screws with the $0 so force the basename into
          # LOADED_FEATURES so we can reload correctly.
          $LOADED_FEATURES.unshift(File.basename($0))

          @middlewares.unshift([::Rack::Reloader, 0, nil])
        end
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
      def use(name, args = nil, &block)
        middlewares.push([name, args, block])
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

      # Returns the router maps configured for the API
      #
      # @return [Array] array contains [path, block]
      def maps
        @maps ||= []
      end

      # Specify a router map to be used by the API
      #
      # @example
      #  map '/version' do
      #    run Proc.new {|env| [200, {"Content-Type" => "text/html"}, ["Version 0.1"]] }
      #  end
      #
      # @param name [String] The URL path to map
      # @param block The code to execute
      def map(name, &block)
        maps.push([name, block])
      end
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
      Thread.current[Goliath::Constants::GOLIATH_ENV]
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

    # {#call} is executed automatically by the middleware chain and will setup
    # the environment for the {#response} method to execute. This includes setting
    # up a new Fiber, handing any execptions thrown from the API and executing
    # the appropriate callback method for the API.
    #
    # @param env [Goliath::Env] The request environment
    # @return [Goliath::Connection::AsyncResponse] An async response.
    def call(env)
      Fiber.new {
        begin
          Thread.current[Goliath::Constants::GOLIATH_ENV] = env
          status, headers, body = response(env)

          if body == Goliath::Response::STREAMING
            env[Goliath::Constants::STREAM_START].call(status, headers)
          else
            env[Goliath::Constants::ASYNC_CALLBACK].call([status, headers, body])
          end

        rescue Exception => e
          env.logger.error(e.message)
          env.logger.error(e.backtrace.join("\n"))

          env[Goliath::Constants::ASYNC_CALLBACK].call([400, {}, {:error => e.message}])
        end
      }.resume

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
      [400, {}, {:error => 'No response implemented'}]
    end
  end
end
