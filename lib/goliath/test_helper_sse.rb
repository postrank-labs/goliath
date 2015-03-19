require 'em-eventsource'

module Goliath
  module TestHelper
    class SSEHelper
      attr_reader :connection
      def initialize(url)
        @message_queue = EM::Queue.new
        @named_queues = {}
        @connection = EM::EventSource.new(url)
      end

      def listen
        @connection.message do |message|
          @message_queue.push(message)
        end
      end

      def listen_to(name)
        queue = (@named_queues[name] ||= [])
        @connection.on(name) do |message|
          queue.push(message)
        end
      end

      def receive
        pop_queue(@message_queue)
      end

      def receive_on(name)
        queue = @named_queues.fetch(name) do
          raise ArgumentError, "You have to call listen_to('#{name}') first"
        end

        pop_queue(queue)
      end

      def with_async_http
        klass = EM::HttpConnection
        if klass.instance_methods.include?(:aget)
          begin
            klass.send(:class_eval) do
              alias :sget :get
              alias :get :aget
            end
            yield if block_given?
          ensure
            klass.send(:class_eval) do
              alias :get :sget
              remove_method :sget
            end
          end
        else
          yield if block_given?
        end
      end

      protected

      def pop_queue(queue)
        fiber = Fiber.current
        queue.pop { |m| fiber.resume(m) }
        Fiber.yield
      end
    end

    def sse_client_connect(path,&blk)
      url = "http://localhost:#{@test_server_port}#{path}"
      client = SSEHelper.new(url)
      client.with_async_http { client.connection.start }
      client.listen
      Fiber.new { blk.call(client) }.resume if blk
      stop
    end
  end
end
