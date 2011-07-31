module Goliath
  module Rack

    #
    # The strategy here is similar to that of EM::Multi. Figuring out what goes
    # on there will help you understand this.
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
      # @return [Goliath::Rack::AsyncBarrier]
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
