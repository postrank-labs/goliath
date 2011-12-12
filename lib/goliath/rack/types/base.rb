module Goliath
  module Rack
    module Types
      class Base
        include Goliath::Rack::Validator

          def initialize
            @short_name = self.class.name.split("::").last
          end

          def coerce(val, default)
            begin
              _coerce(val)
            rescue => e
              return default if default
              raise Goliath::Rack::Validation::FailedCoerce.new(validation_error(400, "#{val} is not a valid #{@short_name} or can't convert into a #{@short_name}."))
            end
          end
      end
    end
  end
end
