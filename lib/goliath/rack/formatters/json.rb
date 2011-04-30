require 'multi_json'

module Goliath
  module Rack
    module Formatters
      # A JSON formatter. Uses MultiJson so you can use the JSON
      # encoder that is right for your project.
      #
      # @example
      #   use Goliath::Rack::Formatters::JSON
      class JSON
        include AsyncMiddleware

        def post_process(env, status, headers, body)
          if json_response?(headers)
            body = [MultiJson.encode(body)]
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
