require 'rack/utils'

module Goliath
  module Rack
    # A middle ware to parse params. This will parse both the
    # query string parameters and the body and place them into
    # the _params_ hash of the Goliath::Env for the request.
    #
    # @example
    #  use Goliath::Rack::Params
    #
    class Params
      def initialize(app)
        @app = app
      end

      def call(env)
        env['params'] = retrieve_params(env)
        @app.call(env)
      end

      def retrieve_params(env)
        params = {}
        params.merge!(::Rack::Utils.parse_query(env['QUERY_STRING']))
        params.merge!(::Rack::Utils.parse_query(env['rack.input'].read)) unless env['rack.input'].nil?
        params
      end
    end
  end
end