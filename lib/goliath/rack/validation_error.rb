module Goliath
  module Rack
    # Middleware to catch {Goliath::Validation::Error} exceptions
    # and returns the [status code, no headers, :error => exception message]
    class ValidationError
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue Goliath::Validation::Error => e
        [e.status_code, {}, {:error => e.message}]
      end
    end
  end
end
