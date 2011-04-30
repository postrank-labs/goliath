module Goliath
  module Rack
    class DefaultResponseFormat
      include Goliath::Rack::AsyncMiddleware

      def post_process(env, status, headers, body)
        return [status, headers, body] if body.respond_to?(:to_ary)

        new_body = []
        if body.respond_to?(:each)
          body.each { |chunk| new_body << chunk }
        else
          new_body << body
        end
        new_body.collect! { |item| item.to_s }

        [status, headers, new_body.flatten]
      end
    end
  end
end
