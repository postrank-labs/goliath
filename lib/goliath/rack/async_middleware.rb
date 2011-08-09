module Goliath
  module Rack
    #
    # Include this to enable middleware that can perform post-processing.
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
    # By including this middleware, you can do that kind of "around" middleware:
    # it lets goliath proceed asynchronously, but still "unwind" the request by
    # walking up the callback chain.
    #
    # @example
    #   class AwesomeMiddleware
    #     include Goliath::Rack::AsyncMiddleware
    #
    #     def call(env)
    #       awesomeness_quotient = 3
    #       # the extra args sent to super are passed along to post_process
    #       super(env, awesomeness_quotient)
    #     end
    #
    #     def post_process(env, status, headers, body, awesomeness_quotient)
    #       new_body = make_totally_awesome(body, awesomeness_quotient)
    #       [status, headers, new_body]
    #     end
    #   end
    #
    # @note Some caveats on writing middleware. Unlike other Rack powered app
    #   servers, Goliath creates a single instance of the middleware chain at
    #   startup, and reuses it for all incoming requests. Since everything is
    #   asynchronous, you can have multiple requests using the middleware chain
    #   at the same time. If your middleware tries to store any instance or
    #   class level variables they'll end up getting stomped all over by the
    #   next request. Everything that you need to store needs to be stored in
    #   local variables.
    module AsyncMiddleware
      include Goliath::Rack::Validator

      # Called by the framework to create the middleware.
      #
      # @param app [Proc] The application
      # @return [Goliath::Rack::AsyncMiddleware]
      def initialize(app)
        @app = app
      end

      # Store the previous async.callback into async_cb and redefines it to be
      # our own. When the asynchronous response is done, Goliath can "unwind"
      # the request by walking up the callback chain.
      #
      # However, you will notice that we execute the post_process method in the
      # default return case. If the validations fail later in the middleware
      # chain before your classes response(env) method is executed, the response
      # will come back up through the chain normally and be returned.
      #
      # To do preprocessing, override this method in your subclass and invoke
      # super(env) as the last line.  Any extra arguments will be made available
      # to the post_process method.
      #
      # @param env [Goliath::Env] The goliath environment
      # @return [Array] The [status_code, headers, body] tuple
      def call(env, *args)

        hook_into_callback_chain(env, *args)

        downstream_resp = @app.call(env)

        if final_response?(downstream_resp)
          status, headers, body = downstream_resp
          post_process(env, status, headers, body, *args)
        else
          return Goliath::Connection::AsyncResponse
        end
      end

      # Put a callback block in the middle of the async_callback chain:
      # * save the old callback chain;
      # * have the downstream callback send results to our proc...
      # * which fires old callback chain when it completes
      def hook_into_callback_chain(env, *args)
        async_callback = env['async.callback']

        # The response from the downstream app is sent to post_process
        # and then directly up the callback chain
        downstream_callback = Proc.new do |status, headers, body|
          new_resp = safely(env){ post_process(env, status, headers, body, *args) }
          async_callback.call(new_resp)
        end

        env['async.callback'] = downstream_callback
      end

      def final_response?(resp)
        resp != Goliath::Connection::AsyncResponse
      end

      # Override this method in your middleware to perform any
      # postprocessing. Note that this can be called in the asynchronous case
      # (walking back up the middleware async.callback chain), or synchronously
      # (in the case of a validation error, or if a downstream middleware
      # supplied a direct response).
      def post_process(env, status, headers, body)
        [status, headers, body]
      end

    end
  end
end
