require 'em-synchrony'
require 'goliath/connection'
require 'goliath/goliath'

module Goliath
  class Server
    attr_accessor :address, :port, :logger, :app, :status, :config, :plugins, :options

    DEFAULT_PORT = 9000
    DEFAULT_ADDRESS = '0.0.0.0'

    def initialize(address = DEFAULT_ADDRESS, port = DEFAULT_PORT)
      self.address = address
      self.port = port

      self.status = {}
      self.config = {}
      @plugins = []
    end

    def start
      EM.synchrony do
        trap("INT")  { EM.stop }
        trap("TERM") { EM.stop }

        EM.epoll

        @config = load_config

        load_plugins

        EM.start_server(address, port, Goliath::Connection) do |conn|
          conn.app = app
          conn.logger = logger
          conn.status = status
          conn.config = config
          conn.options = options
        end

        EM.set_effective_user("nobody") if Goliath.prod?
      end
    end

    def load_config_file(file)
      config = @config
      status = @status
      options = self.options
      return unless File.exists?(file)
      eval(IO.read(file))
    end

    def config_dir
      "#{File.dirname(__FILE__)}/../../config"
    end

    def service(name)
      file = "#{config_dir}/services/#{Goliath.env}/#{name}.rb"
      load_config_file(file)
    end

    def load_environment_config
      file = "#{config_dir}/environments/#{Goliath.env}/#{File.basename($0)}"
      load_config_file(file)
    end

    def load_config
      @config = {}

      file = "#{config_dir}/#{File.basename($0)}"
      load_config_file(file)
      load_environment_config

      @config
    end

    def load_plugins
      @plugins.each do |(name, args)|
        logger.info("Loading #{name.to_s}")
        p = name.new(port, config, status, logger)
        p.run(*args)
      end
    end
  end
end
