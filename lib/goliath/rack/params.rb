require 'multi_json'
require 'rack/utils'

module Goliath
  module Rack
    URL_ENCODED = %r{^application/x-www-form-urlencoded}
    JSON_ENCODED = %r{^application/((vnd\.api\+)?json|javascript)}

    # A middle ware to parse params. This will parse both the
    # query string parameters and the body and place them into
    # the _params_ hash of the Goliath::Env for the request.
    #
    # @example
    #  use Goliath::Rack::Params
    #
    class Params
      module Parser
        def retrieve_params(env)
          params = env['params'] || {}
          begin
            params.merge!(::Rack::Utils.parse_nested_query(env['QUERY_STRING']))
            if env['rack.input']
              post_params = ::Rack::Utils::Multipart.parse_multipart(env)
              unless post_params
                body = env['rack.input'].read
                env['rack.input'].rewind

                unless body.empty?
                  post_params = case(env['CONTENT_TYPE'])
                  when URL_ENCODED then
                    ::Rack::Utils.parse_nested_query(body)
                  when JSON_ENCODED then
                    json = MultiJson.load(body)
                    if json.is_a?(Hash)
                      json
                    else
                      {'_json' => json}
                    end
                  else
                    {}
                  end
                else
                  post_params = {}
                end
              end
              params.merge!(post_params)
            end
          rescue StandardError => e
            raise Goliath::Validation::BadRequestError, "Invalid parameters: #{e.class.to_s}"
          end
          params
        end
      end

      include Goliath::Rack::Validator
      include Parser

      def initialize(app)
        @app = app
      end

      def call(env)
        error_response = Goliath::Rack::Validator.safely(env) do
          env['params'] = retrieve_params(env)
          nil
        end
        error_response || @app.call(env)
      end
    end
  end
end
