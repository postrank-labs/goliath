require 'goliath/request'
require 'goliath/response'

module Goliath
  # @private
  class Connection < EM::Connection
    attr_accessor :app, :request, :response, :port, :logger, :status, :config, :options

    AsyncResponse = [-1, {}, []].freeze

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
        session! if @session.nil?
        request.parse(data)

        if request.finished?
          @session.process
          session!
        end
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