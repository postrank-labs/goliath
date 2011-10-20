module Goliath
  module Validation
    # A information about exceptions raised during validation.
    class Error < StandardError
      # The status code to return from the error handler
      attr_accessor :status_code

      # Create a new Goliath::Validation::Error.
      #
      # @example
      #  raise Goliath::Validation::Error.new(401, "Invalid credentials")
      #
      # @param status_code [Integer] The status code to return
      # @param message [String] The error message to return
      # @return [Goliath::Validation::Error] The Goliath::Validation::Error
      def initialize(status_code, message)
        super(message)
        @status_code = status_code
      end
    end
  end
end
