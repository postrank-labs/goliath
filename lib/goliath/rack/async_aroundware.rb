module Goliath
  module Rack
    class AsyncAroundware
      include Goliath::Rack::Validator

      # Called by the framework to create the middleware.  Any extra args passed
      # to the use statement are sent to each response_receiver_klass as it is created.
      #
      # @example
      #   class Awesomizer2011 < Goliath::Rack::MultiReceiver
      #     def initialize(env, aq)
      #       @awesomeness_quotient = aq
      #       super(env)
      #     end
      #     # ... define pre_process and post_process ...
      #   end
      #
      #   class AwesomeApiWithShortening < Goliath::API
      #     use Goliath::Rack::AsyncAroundware, Awesomizer2011, 3
      #     # ... stuff ...
      #   end
      #
      # @param app [#call] the downstream app
      # @param response_receiver_klass a class that quacks like a
      #   Goliath::Rack::ResponseReceiver and an EM::Deferrable
      # @param *args [Array] extra args to pass to the response_receiver
      # @return [Goliath::Rack::AsyncMiddleware]
      def initialize app, response_receiver_klass, *args
        @app = app
        @response_receiver_klass = response_receiver_klass
        @response_receiver_args  = args
      end

      # This coordinates a response_receiver to process a request. We hook the
      # response_receiver in the middle of the async_callback chain:
      # * send the downstream response to the response_receiver, whether received directly
      #   from @app.call or via async callback
      # * have the upstream callback chain be invoked when the response_receiver completes
      #
      # @param env [Goliath::Env] The goliath environment
      # @return [Array] The [status_code, headers, body] tuple
      def call(env)
        response_receiver = new_response_receiver(env)

        response_receiver_resp = response_receiver.pre_process

        hook_into_callback_chain(env, response_receiver)

        downstream_resp = @app.call(env)

        # if downstream resp is final, pass it to the response_receiver; it will invoke
        # the callback chain at its leisure. Our response is *always* async.
        if final_response?(downstream_resp)
          safely(env){ response_receiver.call(downstream_resp) }
        end
        return Goliath::Connection::AsyncResponse
      end

      # Generate a response_receiver to process the request, using request env & any args
      # passed to this Response_ReceiverMiddleware at creation
      #
      # @param env [Goliath::Env] The goliath environment
      # @return [Goliath::Rack::AsyncResponse_Receiver] The response_receiver to process this request
      def new_response_receiver(env)
        @response_receiver_klass.new(env, *@response_receiver_args)
      end

      # Put response_receiver in the middle of the async_callback chain:
      # * save the old callback chain;
      # * have the downstream callback send results to the response_receiver (possibly
      #   completing it)
      # * set the old callback chain to fire when the response_receiver completes
      def hook_into_callback_chain(env, response_receiver)
        async_callback = env['async.callback']

        # The response from the downstream app is accepted by the response_receiver...
        downstream_callback = Proc.new{|resp| safely(env){ response_receiver.call(resp) } }
        env['async.callback'] = downstream_callback

        # .. but the upstream chain is only invoked when the response_receiver completes
        invoke_upstream_chain = Proc.new do
          response_receiver_resp = safely(env){ response_receiver.post_process }
          async_callback.call(response_receiver_resp)
        end
        response_receiver.callback(&invoke_upstream_chain)
        response_receiver.errback(&invoke_upstream_chain)
      end

      def final_response?(resp)
        resp != Goliath::Connection::AsyncResponse
      end
    end
  end
end
