module Goliath
  module Synchrony

    module ResponseReceiver
      # The request environment, set in the initializer
      attr_reader :env
      # The response, set by the BarrierMiddleware's downstream
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

      # Invoked by the async_callback chain. Stores the [status, headers, body]
      # for post_process'ing
      def call shb
        return shb if shb.first == Goliath::Connection::AsyncResponse.first
        @status, @headers, @body = shb
        succeed if finished?
      end

      # Have we received a response?
      def response_received?
        !! @status
      end
    end

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
