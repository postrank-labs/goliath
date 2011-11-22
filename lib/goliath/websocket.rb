require 'em-websocket'

module Goliath
  class WebSocket < Goliath::API
    include Goliath::Constants

    def on_open(env) ; end
    def on_message(env, msg) ; end
    def on_close(env) ; end
    def on_error(env, error) ; end

    def on_headers(env, headers)
      env['goliath.request-headers'] = headers
    end

    def on_body(env, data)
      env.handler.receive_data(data)
    end

    def response(env)
      request = {}

      # em-websockets expects the keys to all be lowercase so we need to convert
      env['goliath.request-headers'].each_pair do |key, value|
        request[key.downcase] = value
      end

      request['path'] = env[REQUEST_PATH]
      request['method'] = env[REQUEST_METHOD]
      request['query'] = env[QUERY_STRING]

      old_stream_send = env[STREAM_SEND]
      env[STREAM_SEND]  = proc { |data| env.handler.send_text_frame(data) }
      env[STREAM_CLOSE] = proc { env.handler.close_websocket }
      env[STREAM_START] = proc { }

      conn = Class.new do
        def initialize(env, parent, stream_send)
          @env = env
          @parent = parent
          @stream_send = stream_send
        end

        def trigger_on_open
          @parent.on_open(@env)
        end

        def trigger_on_close
          @parent.on_close(@env)
        end

        def trigger_on_message(msg)
          @parent.on_message(@env, msg)
        end

        def close_connection_after_writing
        end

        def send_data(data)
          @stream_send.call(data)
        end
      end.new(env, self, old_stream_send)

      upgrade_data = env[UPGRADE_DATA]

      begin
        env['handler'] = EM::WebSocket::HandlerFactory.build_with_request(conn, request,
                                                                          upgrade_data, false, false)
      rescue Exception => e
        env.logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
        return [500, {}, {:error => "Upgrade failed"}]
      end

      env['handler'].run

      Goliath::Connection::AsyncResponse
    end
  end
end
