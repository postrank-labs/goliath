require 'em-synchrony'
require 'goliath/connection'
require 'goliath/goliath'

module Goliath
  # The server is responsible for listening to the provided port and servicing the requests
  #
  # @private
  class Server
    # The address of the server @example 127.0.0.1
    # @return [String] The server address
    attr_accessor :address

    # The port of the server @example 9000
    # @return [Integer] The server port
    attr_accessor :port

    # The logger for the server
    # @return [Logger] The logger object
    attr_accessor :logger

    # The Rack application
    # @return [Object] The rack application the server will execute
    attr_accessor :app

    # Server status information
    # @return [Hash] Server status information
    attr_accessor :status

    # Server configuration information
    # @return [Hash] Server configuration information
    attr_accessor :config

    # The plugins the server will execute
    # @return [Array] The list of plugins to be executed by the server
    attr_accessor :plugins

    # The server options
    # @return [Hash] Server options
    attr_accessor :options

    # Default execution port
    DEFAULT_PORT = 9000

    # Default execution address
    DEFAULT_ADDRESS = '0.0.0.0'

    # Create a new Goliath::Server
    #
    # @param address [String] The server address (default: DEFAULT_ADDRESS)
    # @param port [Integer] The server port (default: DEFAULT_PORT)
    # @return [Goliath::Server] The new server object
    def initialize(address = DEFAULT_ADDRESS, port = DEFAULT_PORT)
      @address = address
      @port = port

      @status = {}
      @config = {}
      @plugins = []
    end

    # Starts the server running. This will execute the reactor, load config and plugins and
    # start listening for requests
    #
    # @return Does not return until the server has halted.
    def start
      EM.synchrony do
        trap("INT")  { EM.stop }
        trap("TERM") { EM.stop }

        EM.epoll

        load_config
        load_plugins

        EM.start_server(address, port, Goliath::Connection) do |conn|
          conn.port = port
          conn.app = app
          conn.logger = logger
          conn.status = status
          conn.config = config
          conn.options = options
        end

        EM.set_effective_user("nobody") if Goliath.prod?
      end
    end

    # Loads a configuration file
    #
    # @param file [String] The file to load, if not set will use the basename of $0
    # @return [Nil]
    def load_config(file = nil)
      file ||= "#{config_dir}/#{File.basename($0)}"
      return unless File.exists?(file)

      eval(IO.read(file))
    end

    # Retrieves the configuration directory for the server
    #
    # @return [String] THe full path to the config directory
    def config_dir
      "#{File.expand_path(File.dirname($0))}/config"
    end

    # Import callback for configuration files
    # This will trigger a call to load_config with the provided name concatenated to the config_dir
    #
    # @param name [String] The name of the file in config_dir to load
    # @return [Nil]
    def import(name)
      file = "#{config_dir}/#{name}.rb"
      load_config(file)
    end

    # The environment block handling for configuration files
    #
    # @param type [String] The environment load the config block for
    # @param blk [Block] The configuration data to load
    # @return [Nil]
    def environment(type, &blk)
      blk.call if type.to_sym == Goliath.env.to_sym
    end

    # Executes the run method of all set plugins
    #
    # @return [Nil]
    def load_plugins
      @plugins.each do |(name, args)|
        logger.info("Loading #{name.to_s}")

        plugin = name.new(port, config, status, logger)
        plugin.run(*args)
      end
    end
  end
end
