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
          attr_reader :key, :type, :coerce_default, :coerce_message, :required_message, :optional

        # extracted from activesupport 3.0.9
        if defined?(Encoding) && "".respond_to?(:encode)
          NON_WHITESPACE_REGEXP = %r![^[:space:]]!
        else
          NON_WHITESPACE_REGEXP = %r![^\s#{[0x3000].pack("U")}]!
        end

        def initialize(app, opts = {})
          @app = app
          @optional = opts[:optional] || false
          @key = opts[:key] || 'id'
          @coerce_default = opts[:coerce_default]
          @coerce_message = opts[:coerce_message]
          @required_message = opts[:required_message] || 'identifier missing'
          @type = opts[:type] || @key

          if opts[:as]
            unless Class === opts[:as]
              raise Exception.new("Params as must be a class")
            end
            @coerce_instance = opts[:as].new
            unless @coerce_instance.respond_to?(:coerce)
              raise Exception.new("#{@coerce_instance} does not respond to coerce")
            end
          end

          if @key.is_a?(String) && @key.include?('.')
            @key = @key.split('.')
          end
        end

        def call(env)
          unless @optional
            return validation_error(400, "#{@type} #{@required_message}") unless key_valid?(env['params'])
          end

          begin
            coerce_value(env['params']) if @coerce_instance
          rescue FailedCoerce => e
            return e.error unless @optional
          end

          @app.call(env)
        end

        def coerce_value(params)
          opts = {:default => @coerce_default, :failure_message => @coerce_message}
          value_before_coerce = fetch_key(params)
          value_after_coerce = @coerce_instance.coerce(value_before_coerce, opts)
          fetch_key(params, value_after_coerce)
        end

        def key_valid?(params)
          val = fetch_key(params)

          case val
          when nil
            return false

          when String
            # if val is a string it must not be empty
            return false if val !~ NON_WHITESPACE_REGEXP

          when Array
            unless val.compact.empty?
              val.each do |k|
                return true unless k.is_a?(String)
                return true unless k !~ NON_WHITESPACE_REGEXP
              end
            end

            return false
          end

          true
        end

        def fetch_key(params, set_value=nil)
          # cant do ||= because _real_key may be nil
          # Dont want to short circuit with cached version if we want to set a value.
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
