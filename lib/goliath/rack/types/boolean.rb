module Goliath
  module Rack
    module Types
      class Boolean < Base
        def _coerce(val)
          return true if ['true', 't'].include?(val.downcase)
          return false if ['false', 'f'].include?(val.downcase)
          return true if Integer(val) == 1
          return false if Integer(val) == 0
          raise "#{val} not boolean"
        end
      end
    end
  end
end
