require 'goliath/request'

module Goliath
  class API
    def initialize
      @middlewares = []
      @plugins = []
    end

    def options_parser(opts, options)
    end

    def plugins
      plugin
      @plugins
    end

    def load(name, *args)
      @plugins.push([name, args])
    end

    def use(name, args = nil, &block)
      @middlewares.push([name, args, block])
    end

    def middlewares
      use ::Rack::ContentLength

      middleware
      @middlewares
    end

    def call(env)
      Fiber.new {
        begin
          status, headers, response = response(env)
          env[Goliath::Request::ASYNC_CALLBACK].call([status, headers, response])

        rescue Exception => e
          env.logger.error(e.message)
          env.logger.error(e.backtrace.join("\n"))

          env[Goliath::Request::ASYNC_CALLBACK].call([400, {}, {:error => e.message}])
        end
      }.resume

      Goliath::Connection::AsyncResponse
    end

    def middleware
    end

    def plugin
    end

    def response(env)
      env.logger.error('You need to implement response')
      [400, {}, {:error => 'No response implemented'}]
    end

  end
end
