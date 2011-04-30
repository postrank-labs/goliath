require 'goliath/rack/validator'

module Goliath
  module Rack
    module Validation
      # Middleware to validate that a given parameter has a specified value.
      #
      # @example
      #  use Goliath::Rack::Validation::RequiredValue, {:key => 'mode', :values => %w(foo bar)}
      #  use Goliath::Rack::Validation::RequiredValue, {:key => 'baz', :values => 'awesome'}
      #
      class RequiredValue
        include Goliath::Rack::Validator

        attr_reader :key, :values

        # Creates the Goliath::Rack::Validation::RequiredValue validator.
        #
        # @param app The app object
        # @param opts [Hash] The options to create the validator with
        # @option opts [String] :key The key to look for in params (default: id)
        # @option opts [String | Array] :values The values to verify are in the params
        # @return [Goliath::Rack::Validation::RequiredValue] The validator
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key] || 'id'
          @values = [opts[:values]].flatten
        end

        def call(env)
          return validation_error(400, "Provided #{@key} is invalid") unless value_valid?(env['params'])
          @app.call(env)
        end

        def value_valid?(params)
          if !params.has_key?(key) || params[key].nil? ||
              (params[key].is_a?(String) && params[key] =~ /^\s*$/)
            return false
          end

          if params[key].is_a?(Array)
            return false if params[key].empty?
            params[key].each { |k| return false unless values.include?(k) }

          elsif !values.include?(params[key])
            return false
          end

          true
        end
      end
    end
  end
end