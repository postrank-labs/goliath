module Goliath
  module Rack
    module Validator
      module_function

      def validation_error(status_code, msg)
        [status_code, {}, {:error => msg}]
      end

      def self.safely(env)
        begin
          yield
        rescue Goliath::Validation::Error => e
          validation_error(e.status_code, e.message)
        rescue Exception => e
          env.logger.error(e.message)
          env.logger.error(e.backtrace.join("\n"))
          validation_error(500, e.message)
        end
      end
    end
  end
end
