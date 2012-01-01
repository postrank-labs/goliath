module Goliath
  module Rack
    module Types
      class Boolean < Base
        TRUE_STRINGS = ['true', 't', '1']
        FALSE_STRINGS = ['false', 'f', '0']
        ERROR_MESSAGE = "%s is not a boolean value"

        def _coerce(val)
          downcased_val = val.downcase
          return true if TRUE_STRINGS.include?(downcased_val)
          return false if FALSE_STRINGS.include?(downcased_val)
          raise ERROR_MESSAGE % val
        end
      end
    end
  end
end
