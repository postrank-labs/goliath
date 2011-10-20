module Goliath
  module Rack
    # A middleware to wrap the response into a JSONP callback.
    #
    # @example
    #  use Goliath::Rack::JSONP
    #
    class JSONP
      include Goliath::Rack::AsyncMiddleware

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

