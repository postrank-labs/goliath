require 'goliath/response'
require 'goliath/request'

module Goliath
  class API

    GOLIATH_ENV = 'goliath.env'

    class << self
      def middlewares
        @middlewares ||= [[::Rack::ContentLength, nil, nil]]
      end

      def use(name, args = nil, &block)
        middlewares.push([name, args, block])
      end

      def plugins
        @plugins ||= []
      end

      def plugin(name, *args)
        plugins.push([name, args])
      end
    end

    def options_parser(opts, options)
    end

    def env
      Thread.current[GOLIATH_ENV]
    end

    def method_missing(name, *args, &blk)
      name = name.to_s
      if env.has_key?(name)
        env[name]

      elsif !env['config'].nil? && env['config'].has_key?(name)
        env['config'][name]

      else
        super(name, *args, &blk)
      end
    end

    def call(env)
      Fiber.new {
        begin
          Thread.current[GOLIATH_ENV] = env
          status, headers, body = response(env)

          if body == Goliath::Response::STREAMING
            env[Goliath::Request::STREAM_START].call(status, headers)
          else
            env[Goliath::Request::ASYNC_CALLBACK].call(status, headers, body)
          end

        rescue Exception => e
          env.logger.error(e.message)
          env.logger.error(e.backtrace.join("\n"))

          env[Goliath::Request::ASYNC_CALLBACK].call([400, {}, {:error => e.message}])
        end
      }.resume

      Goliath::Connection::AsyncResponse
    end

    def response(env)
      env.logger.error('You need to implement response')
      [400, {}, {:error => 'No response implemented'}]
    end
  end
end
