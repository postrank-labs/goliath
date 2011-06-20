require 'http_router'

module Goliath
  module Rack
    class Builder
      # Builds the rack middleware chain for the given API
      #
      # @param klass [Class] The API class to build the middlewares for
      # @param api [Object] The instantiated API
      # @return [Object] The Rack middleware chain
      def self.build(klass, api)
        ::Rack::Builder.app do
          klass.middlewares.each do |mw_klass, args, blk|
            use(mw_klass, *args, &blk)
          end
          if klass.maps?
            klass.maps.each do |path, route_klass, opts, blk|
              blk ||= Proc.new {
                run Builder.build(route_klass, route_klass.new)
              }
              klass.router.add(path, opts.dup).to {|env|
                env['params'] ||= {}
                env['params'].merge!(env['router.params'])
                ::Rack::Builder.new(&blk).to_app.call(env)
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
