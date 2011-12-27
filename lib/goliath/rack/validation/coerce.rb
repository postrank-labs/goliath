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
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.send :attr_reader, :coerce_default, :coerce_message
        end

        module InstanceMethods
          def coerce_setup!(opts={})
            @coerce_default = opts[:coerce_default]
            @coerce_message = opts[:coerce_message]

            if opts[:as]
              unless Class === opts[:as]
                raise Exception.new("Params as must be a class")
              end
              @coerce_instance = opts[:as].new
              unless @coerce_instance.respond_to?(:coerce)
                raise Exception.new("#{@coerce_instance} does not respond to coerce")
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
            opts = {:default => @coerce_default, :failure_message => @coerce_message}
            value_before_coerce = fetch_key(params)
            value_after_coerce = @coerce_instance.coerce(value_before_coerce, opts)
            fetch_key(params, value_after_coerce)
          end
        end

        module ClassMethods
          attr_reader :coerce_default, :coerce_message
        end
      end
    end
  end
end
