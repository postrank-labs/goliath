module Goliath
  module Synchrony

    #
    # Note: This class is deprecated. Please instead use BarrierAroundware
    # (orchestrates multiple concurrent requests) or SimpleAroundware (like
    # AsyncMiddleware, but with a simpler interface).
    #
    # There are more notes on the lib/goliath/deprecated/async_aroundware docs.
    #
    module ResponseReceiver
      # The request environment, set in the initializer
      attr_reader :env
      # The response, set by the ResponseReceiver's downstream
      attr_accessor :status, :headers, :body

      # Override this method in your middleware to perform any preprocessing
      # (launching a deferred request, perhaps).
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

      # Invoked by the async_callback chain. Stores the [status, headers, body]
      # for post_process'ing
      def call resp
        return resp if resp.first == Goliath::Connection::AsyncResponse.first
        self.downstream_resp = resp
        check_progress(nil)
      end

      # Have we received a response?
      def response_received?
        !! @status
      end

    protected

      def check_progress(fiber)
        if finished?
          succeed
          # continue processing
          fiber.resume(self) if fiber && fiber.alive? && fiber != Fiber.current
        end
      end
    end

    #
    # Note: This class is deprecated. Please instead use BarrierAroundware
    # (orchestrates multiple concurrent requests) or SimpleAroundware (like
    # AsyncMiddleware, but with a simpler interface).
    #
    # There are more notes on the lib/goliath/deprecated/async_aroundware docs.
    #
    class MultiReceiver < EM::Synchrony::Multi
      include ResponseReceiver

      # Create a new MultiReceiver
      # @param env [Goliath::Env] the current environment
      def initialize env
        @env = env
        super()
      end

      alias_method :enqueue, :add

      def successes
        responses[:callback]
      end

      def failures
        responses[:errback]
      end

      # Finished if we received a response and the multi request is finished
      def finished?
        super && response_received?
      end
    end

  end
end
