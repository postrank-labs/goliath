require 'goliath/rack/validator'

module Goliath
  module Rack
    module Validation
      # A middleware to validate that the request had a given HTTP method.
      #
      # @example
      #  use Goliath::Rack::Validation::RequestMethod, %w(GET POST)
      #
      class RequestMethod
        include Goliath::Rack::Validator
        attr_reader :methods

        ERROR = 'Invalid request method'

        # Called by the framework to create the Goliath::Rack::Validation::RequestMethod validator
        #
        # @param app The app object
        # @param methods [Array] The accepted request methods
        # @return [Goliath::Rack::Validation::RequestMethod] The validator
        def initialize(app, methods = [])
          @app = app
          @methods = methods
        end

        def call(env)
          return validation_error(405, ERROR, "Allow" => methods.map{|m| m.to_s.upcase}.join(', ')) unless methods.include?(env['REQUEST_METHOD'])
          @app.call(env)
        end
      end
    end
  end
end