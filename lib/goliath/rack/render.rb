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

      VARY='Vary'
      ACCEPT='Accept'
      SERVER='PostRank Goliath API Server',
      CONTENT_TYPE='Content-Type'
      COMMA=','
      FORMAT='format'
      HTTP_ACCEPT='HTTP_ACCEPT'
      MEDIA_ALL='*/*'
      CHAR_SET="; charset=utf-8"

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

        extra = { CONTENT_TYPE => get_content_type(env),
                  VARY => [headers.delete(VARY), ACCEPT].compact.join(COMMA), 
                  Goliath::Headers::SERVER => SERVER }

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
