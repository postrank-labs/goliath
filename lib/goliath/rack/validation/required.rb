module Goliath
  module Rack
    module Validation
      module Required
        NON_WHITESPACE_REGEXP = %r![^[:space:]]!

        def required_setup!(opts={})
          if @key.is_a?(String) && @key.include?('.')
            @key = @key.split('.')
          end
        end

        def call(env)
          unless @optional
            return validation_error(400, "#{@type} #{@message}") unless key_valid?(env['params'])
          end
          super if defined?(super)
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
      end
    end
  end
end
