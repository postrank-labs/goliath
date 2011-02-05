require 'goliath/rack/validation_error'

module Goliath
  module Rack
    module Validation
      class RequiredValue
        attr_reader :key, :values

        def initialize(app, opts = {})
          @app = app
          @key = opts[:key] || 'id'
          @values = [opts[:values]].flatten
        end

        def call(env)
          value_valid!(env['params'])
          @app.call(env)
        end

        def value_valid!(params)
          error = false
          if !params.has_key?(key) || params[key].nil? ||
              (params[key].is_a?(String) && params[key] =~ /^\s*$/)
            error = true
          end

          if params[key].is_a?(Array)
            error = true if params[key].empty?

            params[key].each do |k|
              unless values.include?(k)
               error = true
               break
              end
            end
          elsif !values.include?(params[key])
            error = true
          end

          raise Goliath::Validation::Error.new(400, "Provided #{@key} is invalid") if error
        end
      end
    end
  end
end