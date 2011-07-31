module Goliath
  module Rack

    #
    # This module gives you ergonomics similar to traditional Rack middleware:
    #
    # * Use instance variables! Each SimpleAroundware is unique to its request.
    # * You have accessors for env and (once in post_process) status, headers,
    #   body -- no more shipping them around to every method.
    #
    # If in your traditional rack middleware you'd do this:
    #
    #     class MyRackMiddleware
    #       def call(env)
    #         get_ready_to_be_totally_awesome()
    #         status, headers, body = @app.call(env)
    #         new_body = make_totally_awesome(body)
    #         [status, headers, new_body]
    #       end
    #     end
    #
    # You'd now do this:
    #
    #     class MyAwesomeAroundware
    #       include Goliath::Rack::SimpleAroundware
    #       def pre_process
    #         get_ready_to_be_totally_awesome()
    #       end
    #       def post_process
    #         new_body = make_totally_awesome(body)
    #         [status, headers, new_body]
    #       end
    #     end
    #
    # And you'd include it in your endpoint like this:
    #
    #     class AwesomeApi < Goliath::API
    #       use Goliath::Rack::SimpleAroundwareFactory, MyAwesomeAroundware
    #     end
    #
    # @example
    #     # count incoming requests, outgoing responses, and
    #     # outgoing responses by status code
    #     class StatsdLogger
    #       include Goliath::Rack::SimpleAroundware
    #       def pre_process
    #         statsd_count("reqs.#{config['statsd_name']}.in")
    #         Goliath::Connection::AsyncResponse
    #       end
    #       def post_process
    #         statsd_count("reqs.#{config['statsd_name']}.out")
    #         statsd_count("reqs.#{config['statsd_name']}.#{status}")
    #         [status, headers, body]
    #       end
    #       def statsd_count(name, count=1, sampling_frac=nil)
    #         # ...
    #       end
    #     end
    #
    #     class AwesomeApiWithLogging < Goliath::API
    #       use Goliath::Rack::Params
    #       use Goliath::Rack::SimpleAroundwareFactory, StatsdLogger
    #       def response(env)
    #         # ... do something awesome
    #       end
    #     end
    #
    module SimpleAroundware
      include Goliath::Rack::Validator

      # The request environment, set in the initializer
      attr_reader :env
      # The response, set by the SimpleAroundware's downstream
      attr_accessor :status, :headers, :body

      # @param env [Goliath::Env] The request environment
      # @return [Goliath::Rack::SimpleAroundware]
      def initialize(env)
        @env = env
      end

      # Override this method in your middleware to perform any preprocessing
      # (launching a deferred request, perhaps).
      #
      # You must return Goliath::Connection::AsyncResponse if you want processing to continue
      #
      # @return [Array] array contains [status, headers, body]
      def pre_process
        Goliath::Connection::AsyncResponse
      end

      # Override this method in your middleware to perform any postprocessing.
      # This will only be invoked when all deferred requests (including the
      # response) have completed.
      #
      # @return [Array] array contains [status, headers, body]
      def post_process
        [status, headers, body]
      end

      # Virtual setter for the downstream middleware/endpoint response
      def downstream_resp=(status_headers_body)
        @status, @headers, @body = status_headers_body
      end

      # On receipt of an async result,
      # * call the setter for that handle if any (on receipt of :shortened_url,
      def accept_response(handle, resp_succ, resp)
        self.downstream_resp = resp
      end

    end
  end
end
