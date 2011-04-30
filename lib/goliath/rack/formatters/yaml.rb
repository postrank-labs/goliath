require 'yaml'

module Goliath
  module Rack
    module Formatters
      # A YAML formatter.
      #
      # @example
      #   use Goliath::Rack::Formatters::YAML
      class YAML
        include Goliath::Rack::AsyncMiddleware

        def post_process(env, status, headers, body)
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

