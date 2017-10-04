module Goliath
  module Rack
    class DefaultResponseFormat
      include Goliath::Rack::AsyncMiddleware

      def post_process(env, status, headers, body)
        if body.is_a?(String)
          [status, headers, [body]]
        else
          [status, headers, body]
        end
      end
    end
  end
end
