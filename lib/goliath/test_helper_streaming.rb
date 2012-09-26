require 'em-http-request'

module Goliath
  module TestHelper
    class StreamingHelper
      attr_reader :connection
      def initialize(url)
        @queue = EM::Queue.new

        fiber = Fiber.current
        @connection = EventMachine::HttpRequest.new(url).get
        @connection.errback do |e|
          puts "Error encountered during connection: #{e}"
          EM::stop_event_loop
        end

        @connection.callback { EM::stop_event_loop }

        @connection.stream { |m| @queue.push(m) }

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

    def streaming_client_connect(path, &blk)
      url = "http://localhost:#{@test_server_port}#{path}"
      client = StreamingHelper.new(url)
      blk.call(client) if blk
      stop
    end
  end
end
