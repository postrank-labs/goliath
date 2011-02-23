require 'http/parser'
require 'goliath/env'

module Goliath
  # @private
  class Connection < EM::Connection
    include Constants

    attr_accessor :app, :request, :port, :logger, :status, :config, :options

    AsyncResponse = [-1, {}, []].freeze

    def post_init
      @parser = Http::Parser.new
      @parser.on_headers_complete = proc do |h|
        env = Goliath::Env.new
        env[OPTIONS]     = options
        env[SERVER_PORT] = port
        env[LOGGER]      = logger
        env[OPTIONS]     = options
        env[STATUS]      = status
        env[CONFIG]      = config
        env[REMOTE_ADDR] = remote_address

        @request = Goliath::Request.new(@app, self, env)
        @request.parse_header(h, @parser)
      end

      @parser.on_body = proc do |data|
        @request.parse(data)
      end

      @parser.on_message_complete = proc do
        @request.process
      end
    end

    def receive_data(data)
      begin
        @parser << data
      rescue HTTP::Parser::Error => e
        terminate_connection
      end
    end

    def unbind
      @request.close
    end

    def terminate_connection
      @request.close
      close_connection_after_writing rescue nil
    end

    def remote_address
      Socket.unpack_sockaddr_in(get_peername)[1]
    rescue Exception
      nil
    end

  end
end