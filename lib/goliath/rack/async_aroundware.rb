module Goliath
  module Rack
    class AsyncAroundware
      # Create a new AsyncAroundware
      #
      # @example
      #   class MyResponseReceiver < Goliath::Rack::MultiReceiver
      #     # ... define pre_process and post_process ...
      #   end
      #
      #   class AsyncAroundwareDemoMulti < Goliath::API
      #     use Goliath::Rack::AsyncAroundware, MyResponseReceiver
      #     # ... stuff ...
      #   end
      #
      # @param app [#call] the downstream app
      # @param response_receiver_klass a class that quacks like a
      #   Goliath::Rack::ResponseReceiver and an EM::Deferrable
      # @param *args [Array] extra args to pass to the response_receiver
      def initialize app, response_receiver_klass, *args
        @app = app
        @response_receiver_klass = response_receiver_klass
        @response_receiver_args  = args
      end

      #
      def call(env)
        response_receiver = new_response_receiver(env)

        # put response_receiver in the middle of the async_callback chain:
        # * save the old callback chain;
        # * put the response_receiver in as the new async_callback;
        # * when the response_receiver completes, invoke the old callback chain
        async_callback = env['async.callback']
        env['async.callback'] = response_receiver
        response_receiver.callback{ do_postprocess(env, async_callback, response_receiver) }
        response_receiver.errback{  do_postprocess(env, async_callback, response_receiver) }

        response_receiver.pre_process

        response_receiver.call(@app.call(env))
      end

      def new_response_receiver(env)
        @response_receiver_klass.new(env, *@response_receiver_args)
      end

      include Goliath::Rack::Validator
      def do_postprocess(env, async_callback, response_receiver)
        Goliath::Rack::Validator.safely(env) do
          async_callback.call(response_receiver.post_process)
        end
      end
    end
  end
end
