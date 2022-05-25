require 'em-synchrony'
require 'einhorn'
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

    # The API application
    # @return [Object] The API application the server will execute
    attr_accessor :api

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

      @options = {}
      @status = {}
      @config = {}
      @plugins = []
    end

    # Starts the server running. This will execute the reactor, load config and plugins and
    # start listening for requests
    #
    # @return Does not return until the server has halted.
    def start(&blk)
      EM.epoll
      EM.synchrony do
        trap("INT")  { stop }
        trap("TERM") { stop }

        if RUBY_PLATFORM !~ /mswin|mingw/
          trap("HUP")  { load_config(options[:config]) }
        end

        load_config(options[:config])
        load_plugins

        EM.set_effective_user(options[:user]) if options[:user]

        config[Goliath::Constants::GOLIATH_SIGNATURE] = start_server(options) do |conn|
          if options[:ssl]
            conn.start_tls(
              :private_key_file => options[:ssl_key],
              :cert_chain_file  => options[:ssl_cert],
              :verify_peer      => options[:ssl_verify]
            )
          end

          conn.port = port
          conn.app = app
          conn.api = api
          conn.logger = logger
          conn.status = status
          conn.config = config
          conn.options = options
        end

        blk.call(self) if blk
      end
    end

    def start_server(options, &blk)
      if options[:einhorn]
        fd_num = Einhorn::Worker.socket!
        socket = Socket.for_fd(fd_num)

        EM.attach_server(socket, Goliath::Connection, &blk)
      else
        EM.start_server(address, port, Goliath::Connection, &blk)
      end
    end

    # Stops the server running.
    def stop
      EM.add_timer(0) do
        logger.info('Stopping server...')
        EM.stop
      end
    end

    # Loads a configuration file
    #
    # @param file [String] The file to load, if not set will use the basename of $0
    # @return [Nil]
    def load_config(file = nil)
      api_name = api.class.to_s.gsub('::', '_').gsub(/([^_A-Z])([A-Z])/,'\1_\2').downcase!
      file ||= "#{config_dir}/#{api_name}.rb"
      return unless File.exist?(file)

      proc = Proc.new {} # create proc to grab binding
      eval(IO.read(file), proc.binding, file)
    end

    # Retrieves the configuration directory for the server
    #
    # @return [String] The full path to the config directory
    def config_dir
      dir = options[:config] ? File.dirname(options[:config]) : './config'
      File.expand_path(dir)
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
    # @param type [String|Array] The environment(s) to load the config block for
    # @param blk [Block] The configuration data to load
    # @return [Nil]
    def environment(type, &blk)
      types = [type].flatten.collect { |t| t.to_sym }
      blk.call if types.include?(Goliath.env.to_sym)
    end

    # Executes the run method of all set plugins
    #
    # @return [Nil]
    def load_plugins
      @plugins.each do |(name, args)|
        logger.info("Loading #{name.to_s}")

        if name.instance_method(:initialize).arity != 5 then
          logger.warn( "Plugins now take 5 parameters (address, port, config, status, logger). " +
              "You appear to be using the old style 4 parameter method (port, config, status, logger). " +
              "Please update your plugins as the 4 parameter method is deprecated." );
          plugin = name.new(port, config, status, logger)
        else
          plugin = name.new(address, port, config, status, logger)
        end

        plugin.run(*args)
      end
    end
  end
end
