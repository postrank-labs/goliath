require 'rack/mime'
require 'rack/respond_to'

module Goliath
  module Rack
    # The render middleware will set the Content-Type of the response
    # based on the provided HTTP_ACCEPT headers.
    #
    # @example
    #  use Goliath::Rack::Render
    #
    class Render
      include ::Rack::RespondTo
      include Goliath::Rack::AsyncMiddleware

      def initialize(app, types = nil)
        @app = app
        ::Rack::RespondTo.media_types = [types].flatten if types
      end

      def post_process(env, status, headers, body)
        ::Rack::RespondTo.env = env

        # the respond_to block is what actually triggers the
        # setting of selected_media_type, so it's required

        respond_to do |format|
          format.json { body }
          format.html { body }
          format.xml { body }
          format.rss { body }
          format.js { body }
          format.yaml { body }
        end

        extra = { 'Content-Type' => get_content_type(env),
                  'Server' => 'PostRank Goliath API Server',
                  'Vary' => [headers.delete('Vary'), 'Accept'].compact.join(',') }

        [status, extra.merge(headers), body]
      end

      def get_content_type(env)
        fmt = env.params['format']
        fmt = fmt.last if fmt.is_a?(Array)

        type = if fmt.nil? || fmt =~ /^\s*$/
          ::Rack::RespondTo.selected_media_type
        else
          ::Rack::RespondTo::MediaType(fmt)
        end

        "#{type}; charset=utf-8"
      end
    end
  end
end
