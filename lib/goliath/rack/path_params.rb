require 'rack/utils'

module Goliath
  module Rack

    # A middleware to parse Rails-style path parameters. This will parse
    # parameters from the request path based on the supplied pattern and
    # place them in the _params_ hash of the Goliath::Env for the request.
    #
    # @example
    #  use Goliath::Rack::Params, '/records/:artist/:title'
    #
    class PathParams

      module Parser

        PARAM = %r{:([^/]+)(\/|$)}
        CAPTURE_GROUP = '(?<\1>[^\/\?]+)\2'

        def retrieve_params(env)
          md = matched_params(env)
          md.names.each_with_object({}) do |key, params|
            params[key] = md[key]
          end
        end

        def matched_params(env)
          request_path(env).match(regexp).tap do |matched|
            raise Goliath::Validation::BadRequestError, "Request path does not match expected pattern: #{request_path(env)}" if matched.nil?
          end
        end

        def request_path(env)
          env[Goliath::Request::REQUEST_PATH]
        end

        def regexp
          @regexp ||= %r{^#{@url_pattern.gsub(PARAM, CAPTURE_GROUP)}\/?$}
        end

      end

      include Goliath::Rack::Validator
      include Parser

      def initialize(app, url_pattern)
        @app = app
        @url_pattern = url_pattern
      end

      def call(env)
        Goliath::Rack::Validator.safely(env) do
          env['params'] ||= {}
          env['params'].merge! retrieve_params(env)
          @app.call(env)
        end
      end

    end
  end
end
