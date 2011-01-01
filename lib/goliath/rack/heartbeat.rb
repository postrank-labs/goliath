module Goliath
  module Rack
    class Heartbeat
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'] == '/status'
          env.status[:status] = 'OK'
          [200, {}, env.status]
        else
          @app.call(env)
        end
      end
    end
  end
end