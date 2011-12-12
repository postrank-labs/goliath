module Goliath
  module Rack
    module Types
      CORE_TYPES = [Integer, String, Float]

      CORE_TYPES.each do |type|
        klass_name = type.name
        klass = Class.new(Base)
        klass.class_eval <<-EOT, __FILE__, __LINE__ + 1
          def _coerce(val)
            Kernel.method(:#{klass_name}).call(val)
          end
        EOT

        const_set(klass_name.to_sym, klass)
      end
    end
  end
end

