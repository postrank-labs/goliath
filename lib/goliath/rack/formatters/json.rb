require 'multi_json'

module Goliath
  module Rack
    module Formatters
      class JSON
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
          if json_response?(headers)
            body = MultiJson.encode(body)
          end
          [status, headers, body]
        end

        def json_response?(headers)
          headers['Content-Type'] =~ %r{^application/(json|javascript)}
        end
      end
    end
  end
end
