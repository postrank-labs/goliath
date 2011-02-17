module Goliath
  module Rack
    module Validation
      # A middleware to validate a given value is boolean. This will attempt to do the following
      # conversions:
      #  true  = 'true'  | 't' | 1
      #  false = 'false' | 'f' | 0
      #
      # If the parameter is not provided the :default is used.
      #
      # @example
      #  use Goliath::Rack::Validation::BooleanValue, {:key => 'raw', :default => false}
      #
      class BooleanValue
        # Called by the framework to create the validator
        #
        # @param app The app object
        # @param opts [Hash] The options hash
        # @option opts [String] :key The key to access in the parameters
        # @option opts [Boolean] :default The default value to set
        # @return [Goliath::Rack::Validation::BooleanValue] The validator
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key]
          raise Exception.new("BooleanValue key required") if @key.nil?

          @default = opts[:default]
        end

        def call(env)
          if !env['params'].has_key?(@key) || env['params'][@key].nil? || env['params'][@key] == ''
            env['params'][@key] = @default

          else
            if env['params'][@key].instance_of?(Array)
              env['params'][@key] = env['params'][@key].first
            end

            if env['params'][@key].downcase == 'true' ||
                env['params'][@key].downcase == 't' ||
                env['params'][@key].to_i == 1
              env['params'][@key] = true

            elsif env['params'][@key].downcase == 'false' ||
                env['params'][@key].downcase == 'f' ||
                env['params'][@key].to_i == 0
              env['params'][@key] = false

            else
              env['params'][@key] = @default
            end
          end

          @app.call(env)
        end
      end
    end
  end
end