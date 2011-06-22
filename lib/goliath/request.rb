require 'eventmachine'
require 'goliath/constants'
require 'goliath/response'
require 'goliath/validation'
require 'async_rack'
require 'stringio'

module Goliath
  # Goliath::Request is responsible for processing a request and returning
  # the result back to the client.
  #
  # @private
  class Request
    include EM::Deferrable
    include Constants

    attr_accessor :app, :conn, :env, :response, :body

    def initialize(app, conn, env)
      @app  = app
      @conn = conn
      @env  = env

      @response = Goliath::Response.new
      @body = StringIO.new(INITIAL_BODY.dup)
      @env[RACK_INPUT] = body
      @env[ASYNC_CALLBACK] = method(:post_process)

      @env[STREAM_SEND]  = proc { |data| callback { @conn.send_data(data) } }
      @env[STREAM_CLOSE] = proc { callback { @conn.terminate_request(false) } }
      @env[STREAM_START] = proc do |status, headers|
        callback do
          @response.status = status
          @response.headers = headers

          @conn.send_data(@response.head)
          @conn.send_data(@response.headers_output)
        end
      end

      @state = :processing
    end

    # Invoked by connection when header parsing is complete.
    # This method is invoked only once per request.
    #
    # @param h [Hash] Request headers
    # @param parser [Http::Parser] The parsed used to parse the request
    # @return [Nil]
    def parse_header(h, parser)
      h.each do |k, v|
        @env[HTTP_PREFIX + k.gsub('-','_').upcase] = v
      end

      %w(CONTENT_TYPE CONTENT_LENGTH).each do |name|
        @env[name] = @env.delete("HTTP_#{name}") if @env["HTTP_#{name}"]
      end

      if @env['HTTP_HOST']
        name, port = @env['HTTP_HOST'].split(':')
        @env[SERVER_NAME] = name if name
        @env[SERVER_PORT] = port if port
      end

      @env[REQUEST_METHOD]  = parser.http_method
      @env[REQUEST_URI]     = parser.request_url
      @env[QUERY_STRING]    = parser.query_string
      @env[HTTP_VERSION]    = parser.http_version.join('.')
      @env[SCRIPT_NAME]     = parser.request_path
      @env[REQUEST_PATH]    = parser.request_path
      @env[PATH_INFO]       = parser.request_path
      @env[FRAGMENT]        = parser.fragment

      begin
        @env[ASYNC_HEADERS].call(@env, h) if @env[ASYNC_HEADERS]
      rescue Exception => e
        server_exception(e)
      end
    end

    # Invoked by connection when new body data is
    # parsed from the existing TCP stream.
    #
    # @note In theory, we can make this stream the
    # data into the processing step for async
    # uploads, etc. This would also require additional
    # callbacks for headers, etc.. Maybe something to
    # explore later.
    #
    # @param data [String] The received data
    # @return [Nil]
    def parse(data)
      begin
        if @env[ASYNC_BODY]
          @env[ASYNC_BODY].call(@env, data)
        else
          @body << data
        end
      rescue Exception => e
        server_exception(e)
      end
    end

    # Called to determine if the request has received all data from the client
    #
    # @return [Boolean] True if all data is received, false otherwise
    def finished?
      @state == :finished
    end

    # Invoked by connection when upstream client
    # terminates the current TCP session.
    #
    # @return [Nil]
    def close
      @response.close rescue nil

      begin
        @env[ASYNC_CLOSE].call(@env) if @env[ASYNC_CLOSE]
      rescue Exception => e
        server_exception(e)
      end
    end

    # Invoked by connection when the parsing of the
    # HTTP request and body complete. From this point
    # all synchronous middleware will run until either
    # an immediate response is served, or an async
    # response is indicated.
    #
    # @return [Nil]
    def process
      Fiber.new {
        begin
          @state = :finished
          @env['rack.input'].rewind if @env['rack.input']
          post_process(@app.call(@env))
        rescue Exception => e
          server_exception(e)
        end
      }.resume
    end

    # Invoked by the app / middleware once the request
    # is complete. A special async code is returned if
    # the response is not ready yet.
    #
    # Sending of the data is deferred until the request
    # is marked as ready to push data by the connection.
    # Hence, two pipelined requests can come in via same
    # connection, first can take take 1s to render, while
    # second may take 0.5. Because HTTP spec does not
    # allow for interleaved data exchange, we block the
    # second request until the first one is done and the
    # data is sent.
    #
    # However, processing on the server is done in parallel
    # so the actual time to serve both requests in scenario
    # above, should be ~1s + data transfer time.
    #
    # @param results [Array] The status, headers and body to return to the client
    # @return [Nil]
    def post_process(results)
      begin
        status, headers, body = results
        return if status && status == Goliath::Connection::AsyncResponse.first

        callback do
          begin
            @response.status, @response.headers, @response.body = status, headers, body
            @response.each { |chunk| @conn.send_data(chunk) }
            @env[RACK_LOGGER].info("Status: #{@response.status}, " +
                                   "Content-Length: #{@response.headers['Content-Length']}, " +
                                   "Response Time: #{"%.2f" % ((Time.now.to_f - @env[:start_time]) * 1000)}ms")

                                   @conn.terminate_request(keep_alive)
          rescue Exception => e
            server_exception(e)
          end
        end

      rescue Exception => e
        server_exception(e)
      end
    end

    private

    # Handles logging server exceptions
    #
    # @param e [Exception] The exception to log
    # @return [Nil]
    def server_exception(e)
      if e.is_a?(Goliath::Validation::Error)
        status, headers, body = [e.status_code, {}, ('{"error":"%s"}'%e.message)]  #
      else
        @env[RACK_LOGGER].error("#{e.message}\n#{e.backtrace.join("\n")}")
        status, headers, body = [500, {}, 'An error happened']
      end
      headers['Content-Length'] = body.bytesize.to_s
      @env[:terminate_connection] = true
      post_process([status, headers, body])
    end

    # Used to determine if the connection should  be kept open
    #
    # @return [Boolean] True to keep the connection open, false otherwise
    def keep_alive
      return false if @env[:terminate_connection]
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
  end
end
