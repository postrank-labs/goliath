require 'goliath/request'
require 'goliath/response'

module Goliath
  # @private
  class Connection < EM::Connection
    attr_accessor :app, :request, :response, :port
    attr_reader :logger, :status, :config, :options

    AsyncResponse = [-1, {}, []].freeze

    def post_init
      @request = Goliath::Request.new
      @response = Goliath::Response.new

      @request.remote_address = remote_address
      @request.async_callback = method(:async_process)

      @request.stream_start = method(:stream_start)
      @request.stream_send = method(:stream_send)
      @request.stream_close = method(:stream_close)
    end

    def receive_data(data)
      begin
        request.parse(data)
        process if request.finished?
      rescue HTTP::Parser::Error => e
        terminate_request
      end
    end

    def process
      @request.port = port.to_s
      post_process(@app.call(@request.env))

    rescue Exception => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      post_process([500, {}, 'An error happened'])
    end

    def async_process(results)
      @response.status, @response.headers, @response.body = *results

      log_request(:async, @response)
      send_response

      terminate_request if not persistent?
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
      terminate_request if not async_response?(results) or not persistent?
    end

    def send_response
      @response.each { |chunk| send_data(chunk) }
    end

    def async_response?(results)
      results && results.first == AsyncResponse.first
    end

    def unbind
      @request.async_close.succeed unless @request.async_close.nil?
      @response.body.fail if @response.body.respond_to?(:fail)
    end

    def terminate_request
      close_connection_after_writing rescue nil
      @request.async_close.succeed
      @response.close rescue nil
    end

    alias :stream_send :send_data
    alias :stream_close :terminate_request
    def stream_start(status, headers)
      send_data(@response.head)
      send_data(@response.headers_output)
    end

    def remote_address
      Socket.unpack_sockaddr_in(get_peername)[1]
    rescue Exception
      nil
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
