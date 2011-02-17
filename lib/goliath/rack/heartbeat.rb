module Goliath
  module Rack
    # A heartbeat mechanism for the server. This will add a _/status_ endpoint
    # that returns status 200 and content OK when executed.
    #
    # @example
    #  use Goliath::Rack::Heartbeat
    #
    class Heartbeat
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/status'
          [200, {}, 'OK']
        else
          @app.call(env)
        end
      end
    end
  end
end