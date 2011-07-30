module Goliath
  module Rack

    #
    module SimpleAroundware
      include Goliath::Rack::Validator

      # The request environment, set in the initializer
      attr_reader :env
      # The response, set by the BarrierMiddleware's downstream
      attr_accessor :status, :headers, :body

      # @param env [Goliath::Env] The request environment
      # @return [Goliath::Rack::AsyncBarrier]
      def initialize(env)
        @env = env
      end

      # Override this method in your middleware to perform any preprocessing
      # (launching a deferred request, perhaps).
      #
      # You must return Goliath::Connection::AsyncResponse if you want processing to continue
      #
      # @return [Array] array contains [status, headers, body]
      def pre_process
        Goliath::Connection::AsyncResponse
      end

      # Override this method in your middleware to perform any postprocessing.
      # This will only be invoked when all deferred requests (including the
      # response) have completed.
      #
      # @return [Array] array contains [status, headers, body]
      def post_process
        [status, headers, body]
      end

      # Virtual setter for the downstream middleware/endpoint response
      def downstream_resp=(status_headers_body)
        @status, @headers, @body = status_headers_body
      end

      # On receipt of an async result,
      # * call the setter for that handle if any (on receipt of :shortened_url,
      def accept_response(handle, resp_succ, resp)
        self.downstream_resp = resp
      end

    end
  end
end
