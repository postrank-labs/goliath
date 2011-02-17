module Goliath
  module Rack
    # Middleware to inject the tracer statistics into the response headers.
    #
    # @example
    #  use Goliath::Rack::Tracer
    #
    class Tracer
      def initialize(app)
        @app = app
      end

      def call(env)
        async_cb = env['async.callback']

        env['async.callback'] = Proc.new do |status, headers, body|
          async_cb.call(post_process(env, status, headers, body))
          env.logger.info env.trace_stats.collect{|s| s.join(':')}.join(', ')
        end

        status, headers, body = @app.call(env)
        post_process(env, status, headers, body)
      end

      def post_process(env, status, headers, body)
        extra = { 'X-PostRank' => env.trace_stats.collect{|s| s.join(': ')}.join(', ')}
        [status, headers.merge(extra), body]
      end
    end
  end
end
