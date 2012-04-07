require 'http_router'

class HttpRouter::Route
  attr_accessor :api_class, :api_options
end

module Goliath
  module Rack
    class Builder < ::Rack::Builder
      attr_accessor :params
      include Params::Parser

      alias_method :original_run, :run
      def run(app)
        raise "run disallowed: please mount a Goliath API class"
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
              route.api_options = opts.delete(:api_options) || {}
              route.api_class = route_klass

              route.to do |env|
                builder = Builder.new
                env['params'] ||= {}
                
                if env['router.params']
                  # transform the keys into string
                  env['params'].merge!( Hash[env['router.params'].map{|k,v| [k.to_s, v] }] )
                end

                builder.params = builder.retrieve_params(env)
                builder.instance_eval(&blk) if blk

                if route_klass
                  route_klass.middlewares.each do |mw|
                    builder.instance_eval { use mw[0], *mw[1], &mw[2] }
                  end
                end

                if route_klass or blk.nil?
                  builder.instance_eval { original_run env.event_handler }
                end

                builder.to_app.call(env)
              end
            end

            original_run klass.router
          else
            original_run api
          end
        end
      end
    end
  end
end
