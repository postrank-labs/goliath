require 'rack/contrib'

module Goliath
  module Rack
    class Cookies
      include Goliath::Rack::AsyncMiddleware

      def call(env)
        req = ::Rack::Request.new(env)

        env['rack.cookies'] = cookies =
          ::Rack::Cookies::CookieJar.new(req.cookies)

        super(env, cookies)
      end

      def post_process(_, status, headers, body, cookies)
        response = ::Rack::Response.new(body, status, headers)
        cookies.finish!(response)

        [status, response.headers, body]
      end
    end
  end
end
