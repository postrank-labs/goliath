require 'rack/utils'

module Goliath
  module Rack
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