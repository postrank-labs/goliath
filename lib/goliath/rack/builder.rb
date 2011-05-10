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
          klass.middlewares.each do |mw|
            use(*(mw[0..1].compact), &mw[2])
          end

          # If you use map you can't use run as
          # the rack builder will blowup.
          if klass.maps.empty?
            run api
          else
            klass.maps.each do |(path, route_klass, blk)|
              if route_klass
                map(path) do
                  route_klass.middlewares.each do |mw|
                    use(*(mw[0..1].compact), &mw[2])
                  end
                  run klass.new
                end
              else
                map(path, &blk)
              end
            end
          end
        end
      end
    end
  end
end
