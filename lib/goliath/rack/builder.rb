require 'http_router'

class HttpRouter::Route
  attr_accessor :api_class
end

module Goliath
  module Rack
    class Builder < ::Rack::Builder
      attr_accessor :params
      attr_reader :inner_app
      include Params::Parser

      alias_method :original_run, :run
      def run(app)
        @inner_app = app
        original_run(app)
      end

      module MappingHandlers
        include Constants
        attr_reader :last_app

        def defer
          defer = EM::DefaultDeferrable.new
          Thread.current[GOLIATH_ENV].defer_stack << defer
          defer
        end

        def on_body(env, body)
          defer.callback do |api|
            api.on_body(env, body) if api.respond_to?(:on_body)
          end
        end

        def on_headers(env, headers)
          defer.callback do |api|
            api.on_headers(env, headers) if api.respond_to?(:on_headers)
          end
        end

        def on_close(env)
          defer.callback do |api|
            api.on_close(env) if api.respond_to?(:on_close)
          end
        end
      end

      # Builds the rack middleware chain for the given API
      #
      # @param klass [Class] The API class to build the middlewares for
      # @param api [Object] The instantiated API
      # @return [Object] The Rack middleware chain
      def self.build(klass, api)
        Builder.app do
          klass.middlewares.each do |mw_klass, args, blk|
            use(mw_klass, *args, &blk)
          end
          if klass.maps?
            klass.instance_eval "include MappingHandlers", __FILE__, __LINE__
            klass.maps.each do |path, route_klass, opts, blk|
              route = klass.router.add(path, opts.dup)
              route.api_class = route_klass
              route.to {|env|
                builder = Builder.new
                env['params'] ||= {}
                env['params'].merge!(env['router.params']) if env['router.params']
                builder.params = builder.retrieve_params(env)
                builder.instance_eval(&blk) if blk
                route_klass.middlewares.each do |mw|
                  builder.instance_eval { use mw[0], *mw[1], &mw[2] }
                end if route_klass
                if route_klass or blk.nil?
                  builder.instance_eval { run env.event_handler }
                end
                builder.to_app.call(env)
              }
            end
            run klass.router
          else
            run api
          end
        end
      end

    end
  end
end
