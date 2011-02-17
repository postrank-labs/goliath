module Goliath
  module Rack
    # A middleware to wrap the response into a JSONP callback.
    #
    # @example
    #  use Goliath::Rack::JSONP
    #
    class JSONP
      def initialize(app)
        @app = app
      end

      def call(env)
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
          async_cb.call(post_process(env, status, headers, body))
        end
        status, headers, body = @app.call(env)
        post_process(env, status, headers, body)
      end

      def post_process(env, status, headers, body)
        return [status, headers, body] unless env.params['callback']

        response = ""
        if body.respond_to?(:each)
          body.each { |s| response << s }
        else
          response = body
        end

        [status, headers, ["#{env.params['callback']}(#{response})"]]
      end
    end
  end
end

