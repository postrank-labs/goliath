require 'rack/mime'
require 'rack/respond_to'

module Goliath
  module Rack
    # Does some basic cleanup / handling of the HTTP_ACCEPT header.
    # This will remove gzip, deflate, compressed and identity. If
    # there are no values left the header will be set to \*/\*.
    #
    # @example
    #   use Goliath::Rack::DefaultMimeType
    #
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
