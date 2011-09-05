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
                  raise "You cannot use `run' and supply a routing class at the same time" if builder.inner_app
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
