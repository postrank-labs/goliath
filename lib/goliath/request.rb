module Goliath
  # @private
  class Request
    include Constants
    attr_accessor :app, :conn, :env, :response, :body

    def initialize(app, conn, env)
      @app  = app
      @conn = conn
      @env  = env

      @response = Goliath::Response.new
      @body = StringIO.new(INITIAL_BODY.dup)
      @env[RACK_INPUT] = body

      @env[ASYNC_CLOSE]    = EM::DefaultDeferrable.new
      @env[ASYNC_CALLBACK] = method(:async_process)

      @env[STREAM_SEND]  = proc { @conn.send_data(data) }
      @env[STREAM_CLOSE] = proc { @conn.terminate_request }
      @env[STREAM_START] = proc do
        @conn.send_data(@response.head)
        @conn.send_data(@response.headers_output)
      end

      @state = :processing
    end

    def parse_header(h, parser)
      h.each do |k, v|
        @env[HTTP_PREFIX + k.gsub('-','_').upcase] = v
      end

      @env[STATUS]          = parser.status_code
      @env[REQUEST_METHOD]  = parser.http_method
      @env[REQUEST_URI]     = parser.request_url
      @env[QUERY_STRING]    = parser.query_string
      @env[HTTP_VERSION]    = parser.http_version.join('.')
      @env[SCRIPT_NAME]     = parser.request_path
      @env[REQUEST_PATH]    = parser.request_path
      @env[PATH_INFO]       = parser.request_path
      @env[FRAGMENT]        = parser.fragment
    end

    def parse(data)
      @body << data
    end

    def finished?
      @state == :finished
    end

    def succeed
      @env[ASYNC_CLOSE].succeed if @env[ASYNC_CLOSE]
    end

    #
    # Request processing
    #

    def process
      begin
        @state = :finished
        post_process(@app.call(@env))

      rescue Exception => e
        @env[LOGGER].error("#{e.message}\n#{e.backtrace.join("\n")}")
        post_process([500, {}, 'An error happened'])
      end
    end

    def post_process(results)
      begin
        results = results.to_a
        return if async_response?(results)

        @response.status, @response.headers, @response.body = *results
        log_request(:sync, @response)
        send_response

      rescue Exception => e
        @env[LOGGER].error("#{e.message}\n#{e.backtrace.join("\n")}")

      ensure
        @conn.terminate_request if not async_response?(results) or not keep_alive?
      end
    end

    def async_process(results)
      @response.status, @response.headers, @response.body = *results
      log_request(:async, @response)

      send_response
      @conn.terminate_request if not keep_alive?
    end

    def send_response
      @response.each { |chunk| @conn.send_data(chunk) }
    end

    private

      def async_response?(results)
        results && results.first == Goliath::Connection::AsyncResponse.first
      end

      def keep_alive?
        case @env[HTTP_VERSION]
          # HTTP 1.1: all requests are persistent requests, client
          # must send a Connection:close header to indicate otherwise
          when '1.1' then
            (@env[HTTP_PREFIX + CONNECTION].downcase != 'close') rescue true

            # HTTP 1.0: all requests are non keep-alive, client must
            # send a Connection: Keep-Alive to indicate otherwise
          when '1.0' then
            (@env[HTTP_PREFIX + CONNECTION].downcase == 'keep-alive') rescue false
        end
      end

      def log_request(type, response)
        @env[LOGGER].info("#{type} status: #{@response.status}, " +
                          "Content-Length: #{@response.headers['Content-Length']}, " +
                          "Response Time: #{"%.2f" % ((Time.now.to_f - @env[:start_time]) * 1000)}ms")
      end

  end
end