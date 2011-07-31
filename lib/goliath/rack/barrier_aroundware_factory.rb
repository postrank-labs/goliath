module Goliath
  module Rack
    #
    # Include this to enable middleware that can perform pre- and
    # post-processing, orchestrating multiple concurrent requests.
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
    # This class creates an "aroundware" helper to do that kind of
    # processing. Goliath proceeds asynchronously, but will still "unwind" the
    # request by walking up the callback chain. Delegating out to the aroundware
    # also lets you carry state around -- the ban on instance variables no
    # longer applies, as each aroundware is unique per request.
    #
    # The strategy here is similar to that in EM::Multi. Figuring out what goes
    # on there will help you understand this.
    #
    # @see EventMachine::Multi
    # @see Goliath::Rack::SimpleAroundware
    # @see Goliath::Rack::SimpleAroundwareFactory
    # @see Goliath::Rack::BarrierAroundware
    #
    class BarrierAroundwareFactory < Goliath::Rack::SimpleAroundwareFactory
      include Goliath::Rack::Validator

      # Put aroundware in the middle of the async_callback chain:
      # * save the old callback chain;
      # * have the downstream callback send results to the aroundware (possibly
      #   completing it)
      # * set the old callback chain to fire when the aroundware completes
      def hook_into_callback_chain(env, aroundware)
        async_callback = env['async.callback']

        # The response from the downstream app is accepted by the aroundware...
        downstream_callback = Proc.new do |resp|
          safely(env){ aroundware.accept_response(:downstream_resp, true, resp) }
        end

        # .. but the upstream chain is only invoked when the aroundware completes
        invoke_upstream_chain = Proc.new do
          new_resp = safely(env){ aroundware.post_process }
          async_callback.call(new_resp)
        end

        env['async.callback'] = downstream_callback
        aroundware.add_to_pending(:downstream_resp)
        aroundware.callback(&invoke_upstream_chain)
        aroundware.errback(&invoke_upstream_chain)
      end

    end
  end
end
