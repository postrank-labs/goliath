module Goliath
  module Validation
    class Error < StandardError
      attr_accessor :status_code

      def initialize(status_code, message)
        super(message)
        @status_code = status_code
      end
    end
  end

  module Rack
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