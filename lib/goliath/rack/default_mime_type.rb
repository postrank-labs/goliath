require 'rack/mime'
require 'rack/respond_to'

module Goliath
  module Rack
    class DefaultMimeType

      def initialize(app)
        @app = app
      end

      def call(env)
        accept = env['HTTP_ACCEPT'] || ''
        accept = accept.split(/\s*,\s*/)
        accept.delete_if { |a| a =~ /gzip|deflate|compressed|identity/ }
        accept = accept.join(", ")

        env['HTTP_ACCEPT'] = accept
        env['HTTP_ACCEPT'] = '*/*' if env['HTTP_ACCEPT'] == ''
        @app.call(env)
      end
    end
  end
end
