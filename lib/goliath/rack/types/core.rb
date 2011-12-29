module Goliath
  module Rack
    module Types
      CORE_TYPES = [Integer, Float]

      CORE_TYPES.each do |type|
        klass = Class.new(Base)
        klass.class_eval <<-EOT, __FILE__, __LINE__ + 1
          def _coerce(val)
            #{type}(val)
          end
        EOT

        const_set(type.name, klass)
      end
    end
  end
end

