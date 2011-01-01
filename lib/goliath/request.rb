require 'stringio'
require 'goliath_parser/goliath_parser'
require 'goliath/env'

module Goliath
  class Request
    attr_accessor :env, :body

    INITIAL_BODY = ''
    # Force external_encoding of request's body to ASCII_8BIT
    INITIAL_BODY.encode!(Encoding::ASCII_8BIT) if INITIAL_BODY.respond_to?(:encode)

    SERVER_SOFTWARE = 'SERVER_SOFTWARE'.freeze
    SERVER = "Goliath".freeze

    SERVER_NAME = 'SERVER_NAME'.freeze
    LOCALHOST = 'localhost'.freeze
    REMOTE_ADDR = 'REMOTE_ADDR'.freeze
    CONTENT_LENGTH = 'CONTENT_LENGTH'.freeze
    LOGGER = 'logger'.freeze
    STATUS = 'status'.freeze
    CONFIG = 'config'.freeze
    OPTIONS = 'options'.freeze

    MAX_HEADER = 1024 * (80 + 32)

    RACK_INPUT = 'rack.input'.freeze
    RACK_VERSION = 'rack.version'.freeze
    RACK_ERRORS = 'rack.errors'.freeze
    RACK_MULTITHREAD = 'rack.multithread'.freeze
    RACK_MULTIPROCESS = 'rack.multiprocess'.freeze
    RACK_RUN_ONCE = 'rack.run_once'.freeze
    RACK_VERSION_NUM  = [1, 0].freeze

    ASYNC_CALLBACK = 'async.callback'.freeze
    ASYNC_CLOSE = 'async.close'.freeze

    def initialize(options = {})
      self.body = StringIO.new(INITIAL_BODY.dup)

      @data = ''
      @nparsed = 0

      self.env = Goliath::Env.new
      self.env[SERVER_SOFTWARE] = SERVER
      self.env[SERVER_NAME] = LOCALHOST
      self.env[RACK_INPUT] = body
      self.env[RACK_VERSION] = RACK_VERSION_NUM
      self.env[RACK_ERRORS] = STDERR
      self.env[RACK_MULTITHREAD] = false
      self.env[RACK_MULTIPROCESS] = false
      self.env[RACK_RUN_ONCE] = false
      self.env['options'] = options
    end

    def parser
      @parser ||= Goliath::HttpParser.new
    end

    def parse(data)
      if parser.headers_finished?
        body << data
      else
        @data << data
        raise Goliath::InvalidRequest, 'Header longer than allowed' if @data.size > MAX_HEADER

        @nparsed = parser.execute(env, @data, @nparsed)
      end

      if finished?
        @data = nil
        body.rewind
      end
    end

    def finished?
      parser.headers_finished? && body.size >= content_length
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