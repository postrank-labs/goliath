module Goliath
  module Rack
    module Types
      class Boolean < Base
        TRUE_STRINGS = ['true', 't']
        FALSE_STRINGS = ['false', 'f']
        ERROR_MESSAGE = "%s is not a boolean value"

        def _coerce(val)
          downcased_val = val.downcase
          return true if TRUE_STRINGS.include?(downcased_val)
          return false if FALSE_STRINGS.include?(downcased_val)
          return true if Integer(val) == 1
          return false if Integer(val) == 0
          raise ERROR_MESSAGE % val
        end
      end
    end
  end
end
