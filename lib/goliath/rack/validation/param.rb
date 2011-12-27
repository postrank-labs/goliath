module Goliath
  module Rack
    module Validation
      class FailedCoerce < StandardError
        attr_reader :error
        def initialize(error)
          @error = error
        end
      end

      class Param
        include Goliath::Rack::Validator
        include Coerce
        include Required

        attr_reader :key, :type, :optional

        def initialize(app, opts = {})
          @app = app
          @optional = opts[:optional] || false
          @key = opts[:key] || 'id'
          @type = opts[:type] || @key

          coerce_setup!(opts)
          required_setup!(opts)
        end

        def call(env)
          previous_call = super
          return previous_call if previous_call

          @app.call(env)
        end

        def fetch_key(params, set_value=nil)
          key_path = Array(@key)
          current_value = params

          # check that the full path is present
          # omit the last part of the path
          val = key_path[0...-1].each do |key_part|
            # if the key is missing or is nil
            if !current_value.is_a?(Hash) || current_value[key_part].nil?
              break
            end

            current_value = current_value[key_part]
          end

          current_value[key_path[-1]] = set_value unless set_value.nil?
          val.nil? ? val : current_value[key_path[-1]]
        end
      end
    end
  end
end
