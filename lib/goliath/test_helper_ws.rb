require 'em-websocket-client'

module Goliath
  module TestHelper
    class WSHelper
      attr_reader :connection
      def initialize(url)
        @queue = EM::Queue.new

        fiber = Fiber.current
        @connection = EventMachine::WebSocketClient.connect(url)
        @connection.errback do |e|
          puts "Error encountered during connection: #{e}"
          EM::stop_event_loop
        end

        @connection.callback do
          fiber.resume
        end

        @connection.disconnect do
          EM::stop_event_loop
        end

       @connection.stream do |m|
          @queue.push(m)
        end
       Fiber.yield
      end

      def send(m)
        @connection.send_msg(m)
      end

      def receive
        fiber = Fiber.current
        @queue.pop {|m| fiber.resume(m) }
        Fiber.yield
      end
    end

    def ws_client_connect(path,&blk)
      url = "ws://localhost:#{@test_server_port}#{path}"
      client = WSHelper.new( url )
      blk.call( client ) if blk
      stop
    end
  end
end
