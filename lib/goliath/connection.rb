require 'http/parser'

module Goliath
  # @private
  class Connection < EM::Connection
    attr_accessor :app, :request, :response, :port, :logger, :status, :config, :options

    AsyncResponse = [-1, {}, []].freeze

    def post_init
      @parser = Http::Parser.new
      @parser.on_headers_complete = proc do |h|
        session!
        @session.request.parse_header(h, @parser)
      end

      @parser.on_body = proc do |data|
        @session.request.parse(data)
      end

      @parser.on_message_complete = proc do
        @session.process
      end
    end

    def session!
      @session = Goliath::Session.new(self)
      @session.app = app
      @session.logger = logger
      @session.status = status
      @session.config = config
      @session.options = options
    end

    def request
      @session.request
    end

    def receive_data(data)
      begin
        @parser << data
      rescue HTTP::Parser::Error => e
        terminate_request
      end
    end

    def unbind
      @session.request.async_close.succeed unless @session.request.async_close.nil?
      @session.response.body.fail if @session.response.body.respond_to?(:fail)
    end

    def terminate_request
      close_connection_after_writing rescue nil
      @session.request.async_close.succeed
      @session.response.close rescue nil
    end

    def remote_address
      Socket.unpack_sockaddr_in(get_peername)[1]
    rescue Exception
      nil
    end

  end
end