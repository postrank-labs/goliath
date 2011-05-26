module Goliath
  module Rack
    class Builder
      # Builds the rack middleware chain for the given API
      #
      # @param klass [Class] The API class to build the middlewares for
      # @param api [Object] The instantated API
      # @return [Object] The Rack middleware chain
      def self.build(klass, api)
        ::Rack::Builder.app do
          klass.middlewares.each do |mw_klass, args, blk|
            use(mw_klass, *args, &blk)
          end

          klass.maps.each do |path, route_klass, blk|
            blk ||= Proc.new {
              run Builder.build(route_klass, route_klass.new)
            }
            map(path, &blk)
          end

          run api unless klass.maps?
        end
      end

    end
  end
end
