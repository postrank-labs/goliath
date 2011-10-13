module Goliath
  module Rack
    #
    # Include this to enable middleware that can perform pre- and
    # post-processing.
    #
    # For internal reasons, you can't do the following as you would in Rack:
    #
    #   def call(env)
    #     # ... do pre-processing
    #     status, headers, body = @app.call(env)
    #     new_body = make_totally_awesome(body) ## !! BROKEN !!
    #     [status, headers, new_body]
    #   end
    #
    # This class creates a "aroundware" helper to do that kind of
    # processing. Goliath proceeds asynchronously, but will still "unwind" the
    # request by walking up the callback chain. Delegating out to the aroundware
    # also lets you carry state around -- the ban on instance variables no
    # longer applies, as each aroundware is unique per request.
    #
    # @see Goliath::Rack::AsyncMiddleware
    # @see Goliath::Rack::SimpleAroundware
    # @see Goliath::Rack::BarrierAroundware
    #
    class SimpleAroundwareFactory
      include Goliath::Rack::Validator

      # Called by the framework to create the middleware.
      #
      # Any extra args passed to the use statement are sent to each
      # aroundware_klass as it is created.
      #
      # @example
      #   class Awesomizer2011
      #     include Goliath::Rack::SimpleAroundware
      #     def initialize(env, aq)
      #       @awesomeness_quotient = aq
      #       super(env)
      #     end
      #     # ... define pre_process and post_process ...
      #   end
      #
      #   class AwesomeApiWithShortening < Goliath::API
      #     use Goliath::Rack::SimpleAroundwareFactory, Awesomizer2011, 3
      #     # ... stuff ...
      #   end
      #
      # @param app [#call] the downstream app
      # @param aroundware_klass a class that quacks like a
      #   Goliath::Rack::SimpleAroundware and an EM::Deferrable
      # @param *args [Array] extra args to pass to the aroundware
      # @return [Goliath::Rack::AroundwareFactory]
      def initialize app, aroundware_klass, *args
        @app = app
        @aroundware_klass = aroundware_klass
        @aroundware_args  = args
      end

      # Coordinates aroundware to process a request.
      #
      # We hook the aroundware in the middle of the async_callback chain:
      # * send the downstream response to the aroundware, whether received directly
      #   from @app.call or via async callback
      # * have the upstream callback chain be invoked when the aroundware completes
      #
      # @param env [Goliath::Env] The goliath environment
      # @return [Array] The [status_code, headers, body] tuple
      def call(env)
        aroundware = new_aroundware(env)

        aroundware_resp = aroundware.pre_process
        return aroundware_resp if final_response?(aroundware_resp)

        hook_into_callback_chain(env, aroundware)

        downstream_resp = @app.call(env)

        # if downstream resp is final, pass it to the aroundware; it will invoke
        # the callback chain at its leisure. Our response is *always* async.
        if final_response?(downstream_resp)
          aroundware.accept_response(:downstream_resp, true, downstream_resp)
        end
        return Goliath::Connection::AsyncResponse
      end

      # Put aroundware in the middle of the async_callback chain:
      # * save the old callback chain;
      # * have the downstream callback send results to the aroundware (possibly
      #   completing it)
      # * set the old callback chain to fire when the aroundware completes
      def hook_into_callback_chain(env, aroundware)
        async_callback = env['async.callback']

        # The response from the downstream app is accepted by the aroundware...
        # ... and we immediately call post_process and hand it upstream
        downstream_callback = Proc.new do |resp|
          safely(env){ aroundware.accept_response(:downstream_resp, true, resp) }
          new_resp = safely(env){ aroundware.post_process }
          async_callback.call(new_resp)
        end

        env['async.callback'] = downstream_callback
      end

      def final_response?(resp)
        resp != Goliath::Connection::AsyncResponse
      end

      # Generate a aroundware to process the request, using request env & any args
      # passed to this AroundwareFactory at creation
      #
      # @param env [Goliath::Env] The goliath environment
      # @return [Goliath::Rack::SimpleAroundware] The aroundware to process this request
      def new_aroundware(env)
        @aroundware_klass.new(env, *@aroundware_args)
      end

    end
  end
end
