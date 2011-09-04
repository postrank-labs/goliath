require 'http_router'

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
            klass.maps.each do |path, route_klass, opts, blk|
              blk ||= Proc.new {
                run Builder.build(route_klass, route_klass.new)
              }
              builder = Builder.new
              builder.instance_eval(&blk)
              route = klass.router.add(path, opts.dup)
              route.event_handler = builder.inner_app
              route.to {|env|
                env['params'] ||= {}
                env['params'].merge!(env['router.params']) if env['router.params']
                builder.params = builder.retrieve_params(env)
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
