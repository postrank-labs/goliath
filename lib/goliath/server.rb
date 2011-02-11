require 'em-synchrony'
require 'goliath/connection'
require 'goliath/goliath'

module Goliath
  class Server
    attr_accessor :address, :port, :logger, :app, :status, :config, :plugins, :options

    DEFAULT_PORT = 9000
    DEFAULT_ADDRESS = '0.0.0.0'

    def initialize(address = DEFAULT_ADDRESS, port = DEFAULT_PORT)
      @address = address
      @port = port

      @status = {}
      @config = {}
      @plugins = []
    end

    def start
      EM.synchrony do
        trap("INT")  { EM.stop }
        trap("TERM") { EM.stop }

        EM.epoll

        load_config
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

    def load_config(file = nil)
      file ||= "#{config_dir}/#{File.basename($0)}"
      return unless File.exists?(file)

      eval(IO.read(file))
    end

    def config_dir
      "#{File.expand_path(File.dirname($0))}/config"
    end

    def import(name)
      file = "#{config_dir}/#{name}.rb"
      load_config(file)
    end

    def environment(type, &blk)
      blk.call if type.to_sym == Goliath.env.to_sym
    end

    def load_plugins
      @plugins.each do |(name, args)|
        logger.info("Loading #{name.to_s}")

        plugin = name.new(port, config, status, logger)
        plugin.run(*args)
      end
    end
  end
end
