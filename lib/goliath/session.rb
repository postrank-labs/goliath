module Goliath

  class Session

    attr_accessor :app, :request, :response, :port
    attr_reader :logger, :status, :config, :options

    def initialize(conn)
      @conn = conn

      @request = Goliath::Request.new
      @response = Goliath::Response.new

      @request.remote_address = @conn.remote_address
      @request.async_callback = method(:async_process)

      @request.stream_start = method(:stream_start)
      @request.stream_send = method(:stream_send)
      @request.stream_close = method(:stream_close)
    end

    def process
      @request.port = port.to_s
      post_process(@app.call(@request.env))

    rescue Exception => e
      puts e.backtrace.join("\n")
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      post_process([500, {}, 'An error happened'])
    end

    def async_process(results)
      @response.status, @response.headers, @response.body = *results

      log_request(:async, @response)
      send_response

      @conn.terminate_request if not persistent?
    end

    def post_process(results)
      results = results.to_a
      return if async_response?(results)

      @response.status, @response.headers, @response.body = *results
      log_request(:sync, @response)
      send_response

    rescue Exception => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")

    ensure
      @conn.terminate_request if not async_response?(results) or not persistent?
    end

    def send_response
      @response.each { |chunk| @conn.send_data(chunk) }
    end

    def async_response?(results)
      results && results.first == Goliath::Connection::AsyncResponse.first
    end

    def stream_send(data)
      @conn.send_data(data)
    end

    def stream_close
      @conn.terminate_request
    end

    def stream_start(status, headers)
      @conn.send_data(@response.head)
      @conn.send_data(@response.headers_output)
    end

    def logger=(logger)
      @logger = logger
      @request.logger = logger
    end

    def status=(status)
      @status = status
      @request.status = status
    end

    def config=(config)
      @config = config
      @request.config = config
    end

    def options=(options)
      @options = options
      @request.options = options
    end

    private

      def log_request(type, response)
        logger.info("#{type} status: #{@response.status}, " +
                    "Content-Length: #{@response.headers['Content-Length']}, " +
                    "Response Time: #{"%.2f" % ((Time.now.to_f - request.env[:start_time]) * 1000)}ms")
      end

      def persistent?
        @request.keep_alive?
      end

  end
end
