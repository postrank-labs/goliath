module Goliath
  module Rack

    #
    # This module gives you ergonomics similar to traditional Rack middleware:
    #
    # * Use instance variables! Each SimpleAroundware is unique to its request.
    # * You have accessors for env and (once in post_process) status, headers,
    #   body -- no more shipping them around to every method.
    #
    # ...along with a new superpower: you can #enqueue requests in #pre_process,
    # and the barrier will hold off on executing #post_process until both the
    # downstream and your enqueued requests have completed.
    #
    # If in your traditional middleware you'd (with poor concurrency) do this:
    #
    #     class MyRackMiddleware
    #       def call(env)
    #         user_info = get_user_from_db
    #         status, headers, body = @app.call(env)
    #         new_body = put_username_into_sidebar_text(body, user_info)
    #         [status, headers, new_body]
    #       end
    #     end
    #
    # You can now do this:
    #
    #     class MyAwesomeAroundware
    #       include Goliath::Rack::BarrierAroundware
    #       attr_accessor :user_info
    #       def pre_process
    #         enqueue :user_info, async_get_user_from_db
    #       end
    #       # !concurrency!
    #       def post_process
    #         new_body = put_username_into_sidebar_text(body, user_info)
    #         [status, headers, new_body]
    #       end
    #     end
    #
    # Which you'd include in your endpoint like this:
    #
    #     class AwesomeApi < Goliath::API
    #       use Goliath::Rack::BarrierAroundwareFactory, MyAwesomeAroundware
    #     end
    #
    # The user record was retrieved from the db while other processing happened;
    # once the async request named :user_info returned, goliath noticed that you
    # had a #user_info= setter and so it set the variable appropriately. (It's
    # also put in the #successes (or #failures) hash).
    #
    # You can also enqueue a non-EM::Deferrable request. #enqueue_acceptor gives
    # you a dummy deferrable; send the response to its succeed method:
    #
    #     # a database lookup that takes a block
    #     enqueue_acceptor(:bob) do |acc|
    #       db.collection(:users).afind(:username => :bob) do |resp|
    #         acc.succeed(resp.first)
    #       end
    #     end
    #
    # You're free to invoke the barrier whenever you like. Consider a bouncer
    # who is polite to townies (he lets them order from the bar while he checks
    # their ID) but a jerk to college kids (who have to wait in line before they
    # can order):
    #
    #     class AuthAroundware
    #       include Goliath::Rack::BarrierAroundware
    #       attr_accessor :user_info
    #       def pre_process
    #         enqueue :user_info, async_get_user_from_db
    #         unless lazy_authorization?
    #           perform               # yield execution until user_info has arrived
    #           check_authorization!  # then check the info *before* continuing
    #         end
    #       end
    #       #
    #       def post_process
    #         check_authorization! if lazy_authorization?
    #         [status, headers, new_body]
    #       end
    #       def lazy_authorization?
    #         (env['REQUEST_METHOD'] == 'GET') || (env['REQUEST_METHOD'] == 'HEAD')
    #       end
    #     end
    #     class AwesomeApi < Goliath::API
    #       use Goliath::Rack::BarrierAroundwareFactory, AuthAroundware
    #     end
    #
    # The `perform` statement puts up a barrier until all pending requests (in
    # this case, :user_info) complete. The downstream request isn't enqueued
    # until pre_process completes, so in the non-`GET` branch the AuthAroundware
    # is able to verify the user *before* allowing execution to proceed. If the
    # request is a harmless `GET`, though, both the user_info and downstream
    # requests can proceed concurrently, and we instead `check_authorization!`
    # in the post_process block.
    #
    # @example
    #     class ShortenUrl
    #       attr_accessor :shortened_url
    #       include Goliath::Rack::BarrierAroundware
    #
    #       def pre_process
    #         target_url        = PostRank::URI.clean(env.params['url'])
    #         shortener_request = EM::HttpRequest.new('http://is.gd/create.php').aget(:query => { :format => 'simple', :url => target_url })
    #         enqueue :shortened_url, shortener_request
    #         Goliath::Connection::AsyncResponse
    #       end
    #
    #       # by the time you get here, the AroundwareFactory will have populated
    #       # the [status, headers, body] and the shortener_request will have
    #       # populated the shortened_url attribute.
    #       def post_process
    #         if succeeded?(:shortened_url)
    #           headers['X-Shortened-URI'] = shortened_url
    #         end
    #         [status, headers, body]
    #       end
    #     end
    #
    #     class AwesomeApiWithShortening < Goliath::API
    #       use Goliath::Rack::Params
    #       use Goliath::Rack::BarrierAroundwareFactory, ShortenUrl
    #       def response(env)
    #         # ... do something awesome
    #       end
    #     end
    #
    module BarrierAroundware
      include EventMachine::Deferrable
      include Goliath::Rack::SimpleAroundware

      # Pool with handles of pending requests
      attr_reader :pending_requests
      # Pool with handles of sucessful requests
      attr_reader :successes
      # Pool with handles of failed requests
      attr_reader :failures

      # @param env [Goliath::Env] The request environment
      # @return [Goliath::Rack::BarrierAroundware]
      def initialize(env)
        @env = env
        @pending_requests = Set.new
        @successes        = {}
        @failures         = {}
      end

      # On receipt of an async result,
      # * remove the tracking handle from pending_requests
      # * and file the response in either successes or failures as appropriate
      # * call the setter for that handle if any (on receipt of :shortened_url,
      #   calls self.shortened_url = resp)
      # * check progress -- succeeds (transferring controll) if nothing is pending.
      def accept_response(handle, resp_succ, resp, req=nil, fiber=nil)
        raise "received response for a non-pending request!" if not pending_requests.include?(handle)
        pending_requests.delete(handle)
        resp_succ ? (successes[handle] = [req, resp]) : (failures[handle] = [req, resp])
        self.send("#{handle}=", resp) if self.respond_to?("#{handle}=")
        check_progress(fiber)
        resp
      end

      # Add a deferred request to the pending pool, and set a callback to
      # #accept_response when the request completes
      def enqueue(handle, deferred_req)
        fiber = Fiber.current
        add_to_pending(handle)
        deferred_req.callback{|resp| safely(env){ accept_response(handle, true,  resp, deferred_req, fiber) } }
        deferred_req.errback{|resp|  safely(env){ accept_response(handle, false, resp, deferred_req, fiber) } }
      end

      # Do you have a method that uses a block, not a deferrable?  This method
      # gives you a deferrable 'acceptor' and enqueues it -- simply call
      # #succeed (or #fail) on the acceptor from within the block, passing it
      # your desired response.
      #
      # @example
      #     # sleep for 1.0 seconds and then complete
      #     enqueue_acceptor(:sleepy)do |acc|
      #       EM.add_timer(1.0){ acc.succeed }
      #     end
      #
      # @example
      #     # a database lookup that takes a block
      #     enqueue_acceptor(:bob) do |acc|
      #       db.collection(:users).afind(:username => :bob) do |resp|
      #         acc.succeed(resp.first)
      #       end
      #     end
      #
      def enqueue_acceptor(handle)
        acceptor = EM::DefaultDeferrable.new
        yield(acceptor)
        enqueue handle, acceptor
      end

      # Register a pending request. If you call this from outside #enqueue, you
      # must construct callbacks that eventually invoke accept_response
      def add_to_pending(handle)
        set_deferred_status(nil) # we're not done yet, even if we were
        @pending_requests << handle
      end

      def finished?
        pending_requests.empty?
      end

      # Perform will yield (allowing other processes to continue) until all
      # pending responses complete.  You're free to enqueue responses, call
      # perform,
      def perform
        Fiber.yield unless finished?
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
  end
end
