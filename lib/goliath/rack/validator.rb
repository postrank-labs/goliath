module Goliath
  module Rack
    class Validator
      def validation_error(status_code, msg)
        [status_code, {}, {:error => msg}]
      end
    end
  end
end
