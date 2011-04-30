module Goliath
  module Rack
    module Validator
      module_function

      def validation_error(status_code, msg)
        [status_code, {}, {:error => msg}]
      end
    end
  end
end
