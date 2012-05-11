module Goliath
  module Rack

    module Validation
      class FailedCoerce < StandardError
        attr_reader :error
        def initialize(error)
          @error = error
        end
      end

      module Coerce
        NOT_CLASS_ERROR = "Params as must be a class"
        INVALID_COERCE_TYPE = "%s does not respond to coerce"

        def coerce_setup!(opts={})
          as = opts.delete(:as)
          if as
            unless Class === as
              raise Exception.new(NOT_CLASS_ERROR)
            end
            @coerce_instance = as.new
            unless @coerce_instance.respond_to?(:coerce)
              raise Exception.new(INVALID_COERCE_TYPE % @coerce_instance)
            end
          end
        end

        def call(env)
          begin
            coerce_value(env['params']) if @coerce_instance
            nil
          rescue FailedCoerce => e
            return e.error unless @optional
          end
          super if defined?(super)
        end

        def coerce_value(params)
          opts = {:default => @default, :message => @message}
          value_before_coerce = fetch_key(params)
          value_after_coerce = @coerce_instance.coerce(value_before_coerce, opts)
          fetch_key(params, value_after_coerce)
        end
      end
    end
  end
end
