module Goliath
  module Synchrony
    #
    # Currently, you must provide in the env a method 'mongo' that returns a mongo
    # collection or collection proxy (probably by setting it up in the config).
    #
    # This will almost certainly change to something less crappy.
    #
    class MongoReceiver
      include Goliath::Synchrony::ResponseReceiver
      include EM::Deferrable
      include Goliath::Rack::Validator

      def initialize(env)
        @env = env
        @pending_queries = 0
      end

      def mongo
        env.mongo
      end

      def finished?
        response_received? && (@pending_queries == 0)
      end

      def enqueue(handle, req_id)
        # ... requests aren't deferrables so they're tracked in @pending_queries
      end

      def find(selector={}, opts={}, &block)
        @pending_queries += 1
        mongo.find(selector, opts) do |result|
          yield result
          @pending_queries -= 1
          self.succeed if finished?
        end
      end

      def first(selector={}, opts={}, &block)
        opts[:limit] = 1
        find(selector, opts) do |result|
          yield result.first
        end
      end

      def insert(*args)
        mongo.insert(*args)
      end
      def update(*args)
        mongo.update(*args)
      end
      def save(*args)
        mongo.save(*args)
      end
      def remove(*args)
        mongo.remove(*args)
      end
    end
  end
end
