require 'goliath/request'
require 'goliath/response'

module Goliath
  class Connection < EM::Connection
    attr_accessor :app, :request, :response
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
      request.parse(data)
      process if request.finished?
    end

    def process
      response.send_close = request.env[Goliath::Request::HEADERS]['Connection']
      post_process(@app.call(@request.env))

    rescue Exception => e
      logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      post_process([500, {}, 'An error happened'])
    end

    def async_process(results)
      @response.status, @response.headers, @response.body = *results

      log_request(:async, @response)
      send_response
      terminate_request
    end

    def stream_start(status, headers)
      send_data(@response.head)
      send_data(@response.headers_output)
    end

    def stream_send(data)
      send_data(data)
    end

    def stream_close
      terminate_request
    end

    def log_request(type, response)
      logger.info("#{type} status: #{@response.status}, " +
                  "Content-Length: #{@response.headers['Content-Length']}, " +
                  "Response Time: #{"%.2f" % ((Time.now.to_f - request.env[:start_time]) * 1000)}ms")
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
      terminate_request if not async_response?(results)
    end

    def send_response
      @response.each { |chunk| send_data(chunk) }
    end

    def async_response?(results)
      results && results.first == AsyncResponse.first
    end

    def terminate_request
      close_connection_after_writing rescue nil
      close_request_response
    end

    def close_request_response
      @request.async_close.succeed
      @response.close rescue nil
    end

    def unbind
      @request.async_close.succeed unless @request.async_close.nil?
      @response.body.fail if @response.body.respond_to?(:fail)
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
  end
end
