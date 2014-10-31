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
        
        callback_length = env.params['callback'].size
        fixed_content_length = headers['Content-Length'].to_i + callback_length + 2
        headers['Content-Length'] = fixed_content_length.to_s
        
        headers[Goliath::Constants::CONTENT_TYPE] = 'application/javascript'
        [status, headers, ["#{env.params['callback']}(#{response})"]]
      end
    end
  end
end

