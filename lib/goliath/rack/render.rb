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
      include Constants
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
          ::Rack::RespondTo.media_types.each do |type|
            format.send(type, Proc.new { body })
          end
        end

        extra = { CONTENT_TYPE_HEADER => get_content_type(env),
                  VARY_HEADER         => [headers.delete(VARY_HEADER),
                                          ACCEPT_HEADER].compact.join(COMMA), 
                  SERVER_HEADER       => SERVER }

        [status, extra.merge(headers), body]
      end

      def get_content_type(env)
        type = if env.respond_to? :params
          fmt = env.params[FORMAT]
          fmt = fmt.last if fmt.is_a?(Array)

          if !fmt.nil? && fmt !~ /^\s*$/
            ::Rack::RespondTo::MediaType(fmt)
          end
        end
        
        type = ::Rack::RespondTo.env[HTTP_ACCEPT] if type.nil?
        type = ::Rack::RespondTo.selected_media_type if type == MEDIA_ALL

        type.nil? ? CHAR_SET : type + CHAR_SET
      end
    end
  end
end
