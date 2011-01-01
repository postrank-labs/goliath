require 'api/v3/lib/goliath/rack/validation_error'

module Goliath
  module Rack
    module Validation
      class RequestMethod
        attr_reader :methods

        ERROR = 'Invalid request method'

        def initialize(app, methods = [])
          @app = app
          @methods = methods
        end

        def call(env)
          raise Goliath::Validation::Error.new(400, ERROR) unless methods.include?(env['REQUEST_METHOD'])
          @app.call(env)
        end
      end
    end
  end
end