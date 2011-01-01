require 'query_string_parser'

module Goliath
  module Rack
    class Params
      include QueryStringParser

      def initialize(app)
        @app = app
      end

      def call(env)
        env['params'] = retrieve_params(env)
        @app.call(env)
      end

      def retrieve_params(env)
        params = {}
        params.merge!(qs_parse(env['QUERY_STRING']))
        params.merge!(qs_parse(env['rack.input'].read)) unless env['rack.input'].nil?
        params
      end
    end
  end
end