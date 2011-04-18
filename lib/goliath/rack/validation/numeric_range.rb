module Goliath
  module Rack
    module Validation
      # A middleware to validate that a parameter value is within a given range. If the value
      # falls outside the range, or is not provided the default will be used, if provided.
      # If no default the :min or :max values will be applied to the parameter.
      #
      # @example
      #  use Goliath::Rack::Validation::NumericRange, {:key => 'num', :min => 1, :max => 30, :default => 10}
      #  use Goliath::Rack::Validation::NumericRange, {:key => 'num', :min => 1.2, :max => 3.5, :default => 2.9, :as => Float}
      #  use Goliath::Rack::Validation::NumericRange, {:key => 'num', :min => 1}
      #  use Goliath::Rack::Validation::NumericRange, {:key => 'num', :max => 10}
      #
      class NumericRange
        # Called by the framework to create the Goliath::Rack::Validation::NumericRange validator
        #
        # @param app The app object
        # @param opts [Hash] The options hash
        # @option opts [String] :key The key to look for in the parameters
        # @option opts [Integer] :min The minimum value
        # @option opts [Integer] :max The maximum value
        # @option opts [Class] :as How to convert: Float will use .to_f, Integer (the default) will use .to_i
        # @option opts [Integer] :default The default to set if outside the range
        # @return [Goliath::Rack::Validation::NumericRange] The validator
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key]
          raise Exception.new("NumericRange key required") if @key.nil?

          @min = opts[:min]
          @max = opts[:max]
          raise Exception.new("NumericRange requires :min or :max") if @min.nil? && @max.nil?

          @coerce_as = opts[:as]
          raise Exception.new("NumericRange requires :as to be Float or Integer (default)") unless [nil, Integer, Float].include?(@coerce_as)

          @default = opts[:default]
        end

        def call(env)
          if !env['params'].has_key?(@key) || env['params'][@key].nil?
            env['params'][@key] = value

          else
            if env['params'][@key].instance_of?(Array) then
              env['params'][@key] = env['params'][@key].first
            end
            env['params'][@key] = coerce(env['params'][@key])

            if (!@min.nil? && env['params'][@key] < @min) || (!@max.nil? && env['params'][@key] > @max)
              env['params'][@key] = value
            end
          end

          @app.call(env)
        end

        def coerce(val)
          (@coerce_as == Float) ? val.to_f : val.to_i
        end

        def value
          @default || @min || @max
        end
      end
    end
  end
end
