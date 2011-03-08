module Goliath
  module Rack
    class DefaultResponseFormat
      def initialize(app)
        @app = app
      end

      def call(env)
        async_cb = env['async.callback']
        env['async.callback'] = Proc.new do |status, headers, body|
          async_cb.call(post_process(status, headers, body))
        end

        status, headers, body = @app.call(env)
        post_process(status, headers, body)
      end

      def post_process(status, headers, body)
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