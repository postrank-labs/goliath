module Goliath
  module Rack
    # A heartbeat mechanism for the server. This will add a _/status_ endpoint
    # that returns status 200 and content OK when executed.
    #
    # @example
    #  use Goliath::Rack::Heartbeat
    #
    class Heartbeat
      def initialize(app, opts = {})
        @app  = app
        @opts = opts
        @opts[:path]     ||= '/status'
        @opts[:response] ||= [200, {}, 'OK']
      end

      def call(env)
        if env['PATH_INFO'] == @opts[:path]
          env[Goliath::Constants::RACK_LOGGER] = Log4r::Logger.root unless @opts[:log]
          @opts[:response]
        else
          @app.call(env)
        end
      end
    end
  end
end
