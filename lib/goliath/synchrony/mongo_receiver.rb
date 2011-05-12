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

      def initialize(env, db_name)
        @env = env
        @pending_queries = 0
        @db = env.config[db_name]
      end

      def db
        @db
      end

      def finished?
        response_received? && (@pending_queries == 0)
      end

      def enqueue(handle, req_id)
        # ... requests aren't deferrables so they're tracked in @pending_queries
      end

      def find(collection, selector={}, opts={}, &block)
        @pending_queries += 1
        db.collection(collection).find(selector, opts) do |result|
          yield result
          @pending_queries -= 1
          self.succeed if finished?
        end
      end

      def first(collection, selector={}, opts={}, &block)
        opts[:limit] = 1
        find(collection, selector, opts) do |result|
          yield result.first
        end
      end

      def insert(collection, *args)
        db.collection(collection).insert(*args)
      end
      def update(collection, *args)
        db.collection(collection).update(*args)
      end
      def save(collection, *args)
        db.collection(collection).save(*args)
      end
      def remove(collection, *args)
        db.collection(collection).remove(*args)
      end
    end
  end
end
