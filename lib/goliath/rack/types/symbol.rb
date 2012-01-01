module Goliath
  module Rack
    module Types
      class Symbol < Base
        ERROR_MESSAGE = "%s can't convert to Symbol"
        def _coerce(val)
          begin
            val.to_sym
          rescue
            raise ERROR_MESSAGE % val
          end
        end
      end
    end
  end
end
