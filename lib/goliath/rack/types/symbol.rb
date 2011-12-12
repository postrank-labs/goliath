module Goliath
  module Rack
    module Types
      class Symbol < Base
        def _coerce(val)
          begin
            val.to_sym
          rescue
            raise "#{val} cant convert to Symbol"
          end
        end
      end
    end
  end
end
