require 'http/parser'
require 'goliath/env'
require 'goliath/constants'
require 'goliath/request'

module Goliath
  # The Goliath::Connection class handles sending and receiving data
  # from the client.
  #
  # @private
  class Connection < EM::Connection
    include Constants

    attr_accessor :app, :api, :port, :logger, :status, :config, :options
    attr_reader   :parser

    AsyncResponse = [-1, {}, []]
    def post_init
      @current = nil
      @requests = []
      @pending  = []

      @parser = Http::Parser.new
      @parser.on_headers_complete = proc do |h|
        env = Thread.current[GOLIATH_ENV] = Goliath::Env.new
        env[SERVER_PORT] = port.to_s
        env[RACK_LOGGER] = logger
        env[OPTIONS]     = options
        env[STATUS]      = status
        env[CONFIG]      = config
        env[REMOTE_ADDR] = remote_address

        r = Goliath::Request.new(@app, self, env)
        r.parse_header(h, @parser) do
          @api.set_event_handler!(env) if @api

          env[ASYNC_HEADERS] = env.event_handler.method(:on_headers) if env.event_handler.respond_to? :on_headers
          env[ASYNC_BODY]    = env.event_handler.method(:on_body)    if env.event_handler.respond_to? :on_body
          env[ASYNC_CLOSE]   = env.event_handler.method(:on_close)   if env.event_handler.respond_to? :on_close
        end

        @requests.push(r)
      end

      @parser.on_body = proc do |data|
        @requests.first.parse(data)
      end

      @parser.on_message_complete = proc do
        req = @requests.shift

        if @current.nil?
          @current = req
          @current.succeed
        else
          @pending.push(req)
        end

        req.process if !@parser.upgrade? && !req.env[:terminate_connection]
      end
    end

    def receive_data(data)
      begin
        @parser << data

        if @parser.upgrade?
          if !@current.env[UPGRADE_DATA]
            @current.env[UPGRADE_DATA] = @parser.upgrade_data
            @current.process
          else
            @current.parse(data)
          end
        end

      rescue HTTP::Parser::Error => e
        terminate_request(false)
      end
    end

    def unbind
      @requests.map { |r| r.close }
      @pending.map  { |r| r.close }
      @current.close if @current
    end

    def terminate_request(keep_alive)
      if req = @pending.shift
        @current = req
        @current.succeed
      elsif @current
        @current.close
        @current = nil
      end

      close_connection_after_writing rescue nil if !keep_alive
    end

    def remote_address
      Socket.unpack_sockaddr_in(get_peername)[1]
    rescue Exception
      nil
    end
  end
end
