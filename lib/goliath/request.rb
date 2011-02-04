require 'stringio'
require 'goliath/env'
require 'http/parser'

module Goliath
  class Request
    attr_accessor :env, :body

    INITIAL_BODY = ''
    # Force external_encoding of request's body to ASCII_8BIT
    INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode)

    SERVER_SOFTWARE = 'SERVER_SOFTWARE'.freeze
    SERVER          = 'Goliath'.freeze

    HTTP_PREFIX     = 'HTTP_'.freeze
    LOCALHOST       = 'localhost'.freeze
    LOGGER          = 'logger'.freeze
    STATUS          = 'status'.freeze
    CONFIG          = 'config'.freeze
    OPTIONS         = 'options'.freeze

    RACK_INPUT      = 'rack.input'.freeze
    RACK_VERSION    = 'rack.version'.freeze
    RACK_ERRORS     = 'rack.errors'.freeze
    RACK_MULTITHREAD  = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE   = 'rack.run_once'.freeze
    RACK_VERSION_NUM  = [1, 0].freeze

    ASYNC_CALLBACK  = 'async.callback'.freeze
    ASYNC_CLOSE     = 'async.close'.freeze

    SERVER_NAME     = 'SERVER_NAME'.freeze
    REMOTE_ADDR     = 'REMOTE_ADDR'.freeze
    CONTENT_LENGTH  = 'CONTENT_LENGTH'.freeze
    REQUEST_METHOD  = 'REQUEST_METHOD'.freeze
    REQUEST_URI     = 'REQUEST_URI'.freeze
    QUERY_STRING    = 'QUERY_STRING'.freeze
    HTTP_VERSION    = 'HTTP_VERSION'.freeze
    REQUEST_PATH    = 'REQUEST_PATH'.freeze
    PATH_INFO       = 'PATH_INFO'.freeze
    FRAGMENT        = 'FRAGMENT'.freeze

    def initialize(options = {})
      self.body = StringIO.new(INITIAL_BODY.dup)

      self.env = Goliath::Env.new
      self.env[SERVER_SOFTWARE]   = SERVER
      self.env[SERVER_NAME]       = LOCALHOST
      self.env[RACK_INPUT]        = body
      self.env[RACK_VERSION]      = RACK_VERSION_NUM
      self.env[RACK_ERRORS]       = STDERR
      self.env[RACK_MULTITHREAD]  = false
      self.env[RACK_MULTIPROCESS] = false
      self.env[RACK_RUN_ONCE]     = false
      self.env[OPTIONS]           = options

      @parser = Http::Parser.new
      @parser.on_body = proc {|data| body << data }
      @parser.on_message_complete = proc { @state = :finished }
      @parser.on_headers_complete = proc do |h|
        h.each do |k,v|
          self.env[HTTP_PREFIX + k.gsub('-','_').upcase] = v
        end

        self.env[STATUS]          = @parser.status_code
        self.env[REQUEST_METHOD]  = @parser.http_method
        self.env[REQUEST_URI]     = @parser.request_url
        self.env[QUERY_STRING]    = @parser.query_string
        self.env[HTTP_VERSION]    = @parser.http_version.join('.')
        self.env[REQUEST_PATH]    = @parser.request_path
        self.env[PATH_INFO]       = @parser.request_path
        self.env[FRAGMENT]        = @parser.fragment
      end

      @state = :processing
    end

    def parser
      @parser
    end

    def parse(data)
      @parser << data
      body.rewind if finished?
    end

    def finished?
      @state == :finished
    end

    def content_length
      env[CONTENT_LENGTH].to_i
    end

    def logger=(logger)
      env[LOGGER] = logger
    end

    def logger
      env[LOGGER]
    end

    def options=(options)
      env[OPTIONS] = options
    end

    def status=(status)
      env[STATUS] = status
    end

    def status
      env[STATUS]
    end

    def config=(config)
      env[CONFIG] = config
    end

    def config
      env[CONFIG]
    end

    def remote_address=(address)
      env[REMOTE_ADDR] = address
    end

    def remote_address
      env[REMOTE_ADDR]
    end

    def async_callback=(callback)
      env[ASYNC_CALLBACK] = callback
      env[ASYNC_CLOSE] = EM::DefaultDeferrable.new
    end

    def async_callback
      env[ASYNC_CALLBACK]
    end

    def async_close
      env[ASYNC_CLOSE]
    end
  end
end
