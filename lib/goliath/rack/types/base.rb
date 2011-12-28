module Goliath
  module Rack
    module Types
      class Base
        include Goliath::Rack::Validator

          def initialize
            @short_name = self.class.name.split("::").last
          end

          def coerce(val, opts={})
            begin
              _coerce(val)
            rescue => e
              return opts[:default] if opts[:default]
              raise Goliath::Rack::Validation::FailedCoerce.new(
                validation_error(400, opts[:message] || e.message)
              )
            end
          end
      end
    end
  end
end
