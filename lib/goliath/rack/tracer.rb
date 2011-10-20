module Goliath
  module Rack
    # Middleware to inject the tracer statistics into the response headers.
    #
    # @example
    #  use Goliath::Rack::Tracer
    #
    class Tracer
      include Goliath::Rack::AsyncMiddleware

      def initialize(app, header_name=nil)
        super(app)
        @header_name = header_name || 'X-PostRank'
      end

      def call(env)
        env.trace 'trace.start'
        shb = super(env)
        env.logger.info env.trace_stats.collect{|s| s.join(':')}.join(', ')
        shb
      end

      def post_process(env, status, headers, body)
        extra = { @header_name => env.trace_stats.collect{|s| s.join(': ')}.join(', ')}
        env.logger.info env.trace_stats.collect{|s| s.join(':')}.join(', ')
        [status, headers.merge(extra), body]
      end
    end
  end
end
