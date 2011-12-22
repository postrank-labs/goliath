require 'time'

# Reads a favicon.ico statically at load time, renders it on any request for
# '/favicon.ico', and sends every other request on downstream.
#
# Rack::Static is a better option if you're serving several static assets.
#
module Goliath
  module Rack
    class Favicon
      def initialize(app, filename)
        @app = app
        @favicon = File.read(File.join(filename))
        @expires  = Time.at(Time.now + (60 * 60 * 24 * 7)).utc.rfc822.to_s
        @last_modified = File.mtime(filename).utc.rfc822.to_s
      end

      def call(env)
        if env['REQUEST_PATH'] == '/favicon.ico'
          env.logger.info('Serving favicon.ico')

          [200, {'Last-Modified' => @last_modified,
                 'Expires' => @expires,
                 'Content-Type' => "image/vnd.microsoft.icon"}, @favicon]
        else
          @app.call(env)
        end
      end
    end
  end
end
