module Goliath
  module Rack
    module Validator
      module_function

      # @param status_code [Integer] HTTP status code for this error.
      # @param msg [String] message to inject into the response body.
      # @param headers [Hash] Response headers to preserve in an error response;
      #   (the Content-Length header, if any, is removed)
      def validation_error(status_code, msg, headers={})
        headers.delete('Content-Length')
        [status_code, headers, {:error => msg}]
      end

      # Execute a block of code safely.
      #
      # If the block raises any exception that derives from
      # Goliath::Validation::Error (see specifically those in
      # goliath/validation/standard_http_errors.rb), it will be turned into the
      # corresponding 4xx response with a corresponding message.
      #
      # If the block raises any other kind of error, we log it and return a
      # less-communicative 500 response.
      #
      # @example
      #   # will convert the ForbiddenError exception into a 403 response
      #   # and an uncaught error in do_something_risky! into a 500 response
      #   safely(env, headers) do
      #     raise ForbiddenError unless account_info['valid'] == true
      #     do_something_risky!
      #     [status, headers, body]
      #   end
      #
      #
      # @param env [Goliath::Env] The current request env
      # @param headers [Hash] Response headers to preserve in an error response
      #
      def safely(env, headers={})
        begin
          yield
        rescue Goliath::Validation::Error => e
          validation_error(e.status_code, e.message, headers)
        rescue Exception => e
          env.logger.error(e.message)
          env.logger.error(e.backtrace.join("\n"))
          validation_error(500, e.message, headers)
        end
      end
    end
  end
end
