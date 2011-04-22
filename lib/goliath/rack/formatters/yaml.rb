require 'yaml'

module Goliath
  module Rack
    module Formatters
      # A YAML formatter.
      #
      # @example
      #   use Goliath::Rack::Formatters::YAML
      class YAML
        # Called by the framework to create the formatter.
        #
        # @return [Goliath::Rack::Formatters::YAML] The YAML formatter.
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
          if yaml_response?(headers)
            body = [body.to_yaml]
          end
          [status, headers, body]
        end

        def yaml_response?(headers)
          headers['Content-Type'] =~ %r{^text/yaml}
        end
      end
    end
  end
end

