module Goliath
  module Rack
    module Validation
      class NumericRange
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key]
          raise Exception.new("NumericRange key required") if @key.nil?

          @min = opts[:min]
          @max = opts[:max]
          raise Exception.new("NumericRange requires :min or :max") if @min.nil? && @max.nil?

          @default = opts[:default]
        end

        def call(env)
          if !env['params'].has_key?(@key) || env['params'][@key].nil?
            env['params'][@key] = value

          else
            if env['params'][@key].instance_of?(Array) then
              env['params'][@key] = env['params'][@key].first
            end
            env['params'][@key] = env['params'][@key].to_i

            if (!@min.nil? && env['params'][@key] < @min) || (!@max.nil? && env['params'][@key] > @max)
              env['params'][@key] = value
            end
          end

          @app.call(env)
        end

        def value
          @default || @min || @max
        end
      end
    end
  end
end