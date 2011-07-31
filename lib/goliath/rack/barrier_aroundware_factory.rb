module Goliath
  module Rack
    #
    # Include this to enable middleware that can perform pre- and
    # post-processing, optionally having multiple responses pending.
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
    # This class creates a "aroundware" helper to do that kind of "around"
    # processing. Goliath proceeds asynchronously, but will still "unwind" the
    # request by walking up the callback chain. Delegating out to the
    # aroundware also lets you carry state around -- the ban on instance
    # variables no longer applies, as each aroundware is unique per request.
    #
    # @example
    #   class ShortenUrl
    #     attr_accessor :shortened_url
    #     include Goliath::Rack::BarrierAroundware
    #
    #     def pre_process
    #       target_url        = PostRank::URI.clean(env.params['url'])
    #       shortener_request = EM::HttpRequest.new('http://is.gd/create.php').aget(:query => { :format => 'simple', :url => target_url })
    #       enqueue :shortened_url, shortener_request
    #       Goliath::Connection::AsyncResponse
    #     end
    #
    #     # by the time you get here, the AroundwareFactory will have populated
    #     # the [status, headers, body] and the shortener_request will have
    #     # populated the shortened_url attribute.
    #     def post_process
    #       if succeeded?(:shortened_url)
    #         headers['X-Shortened-URI'] = shortened_url
    #       end
    #       [status, headers, body]
    #     end
    #   end
    #
    #   class AwesomeApiWithShortening < Goliath::API
    #     use Goliath::Rack::Params
    #     use Goliath::Rack::BarrierAroundwareFactory, ShortenUrl
    #     def response(env)
    #       # ... do something awesome
    #     end
    #   end
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
