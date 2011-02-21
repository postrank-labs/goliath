require 'goliath/env'

module Goliath
  # @private
  class Request
    include Constants

    attr_accessor :env, :body

    def initialize(options = {})
      @body = StringIO.new(INITIAL_BODY.dup)

      @env = Goliath::Env.new
      @env[RACK_INPUT] = @body
      @env[OPTIONS] = options

      @state = :processing
    end

    def parse_header(h, parser)
      # TODO: why? we should always know the port of the server...
      # Extract the server port if defined in the host
      m = HOST_PORT_REGEXP.match(h['Host'])

      if m && m[:host]
        h['Host'] = m[:host]
        @env[SERVER_PORT] ||= m[:port]
      end

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
      body << data
    end

    def finish
      @state = :finished
      body.rewind
    end

    def finished?
      @state == :finished
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

    def content_length; env[CONTENT_LENGTH].to_i; end
    def port=(port_num); env[SERVER_PORT] = port_num; end

    def logger=(logger) env[LOGGER] = logger; end
    def logger;         env[LOGGER] end

    def options=(options) env[OPTIONS] = options; end

    def status=(status) env[STATUS] = status; end
    def status;         env[STATUS]; end

    def config=(config) env[CONFIG] = config; end
    def config;         env[CONFIG]; end

    def remote_address=(address) env[REMOTE_ADDR] = address; end
    def remote_address;          env[REMOTE_ADDR]; end

    def async_close;    env[ASYNC_CLOSE]; end
    def async_callback; env[ASYNC_CALLBACK]; end
    def async_callback=(callback)
      env[ASYNC_CALLBACK] = callback
      env[ASYNC_CLOSE] = EM::DefaultDeferrable.new
    end

    def stream_start=(callback) env[STREAM_START] = callback; end
    def stream_send=(callback)  env[STREAM_SEND] = callback; end
    def stream_close=(callback) env[STREAM_CLOSE] = callback; end
  end
end