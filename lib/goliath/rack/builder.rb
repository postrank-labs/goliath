module Goliath
  module Rack
    class Builder < ::Rack::Builder
      attr_accessor :params
      include Params::Parser

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
          run api
        end
      end
    end
  end
end
