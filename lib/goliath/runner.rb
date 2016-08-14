require 'goliath/goliath'
require 'goliath/server'
require 'goliath/console'
require 'optparse'
require 'log4r'

module Goliath

  # The default run environment, should one not be set.
  DEFAULT_ENV = :development

  # The environment for a Goliath app can come from a variety of different
  # sources.  Due to the loading order of middleware, we must parse this out
  # at load-time rather than run time.
  #
  # Note that, as implemented, you cannot pass -e as part of a compound flag
  # (e.g. `-sve production`) as it won't be picked up.  The example given would
  # have to be provided as `-sv -e production`.
  #
  # For more detail, see: https://github.com/postrank-labs/goliath/issues/18
  class EnvironmentParser

    # Work out the current runtime environment.
    #
    # The sources of environment, in increasing precedence, are:
    #
    #   1. Default (see Goliath::DEFAULT_ENV)
    #   2. RACK_ENV
    #   3. -e/--environment command line options
    #   4. Hard-coded call to Goliath#env=
    #
    # @param argv [Array] The command line arguments
    # @return [Symbol] The current environment
    def self.parse(argv = [])
      env = ENV["RACK_ENV"] || Goliath::DEFAULT_ENV
      if (i = argv.index('-e')) || (i = argv.index('--environment'))
        env = argv[i + 1]
      end
      env.to_sym
    end
  end

  # Set the environment immediately before we do anything else.
  Goliath.env = Goliath::EnvironmentParser.parse(ARGV)

  # The Goliath::Runner is responsible for parsing any provided options, setting up the
  # rack application, creating a logger, and then executing the Goliath::Server with the loaded information.
  class Runner
    # The address of the server @example 127.0.0.1
    # @return [String] The server address
    attr_accessor :address

    # The port of the server @example 9000
    # @return [Integer] The server port
    attr_accessor :port

    # Flag to determine if the server should daemonize
    # @return [Boolean] True if the server should daemonize, false otherwise
    attr_accessor :daemonize

    # Flag to determine if the server should run in verbose mode
    # @return [Boolean] True to turn on verbose mode, false otherwise
    attr_accessor :verbose

    # Flag to determine if the server should log to standard output
    # @return [Boolean] True if the server should log to stdout, false otherwise
    attr_accessor :log_stdout

    # The log file for the server
    # @return [String] The file the server should log too
    attr_accessor :log_file

    # The pid file for the server
    # @return [String] The file to write the servers pid file into
    attr_accessor :pid_file

    # The Rack application
    # @return [Object] The rack application the server will execute
    attr_accessor :app

    # The API application
    # @return [Object] The API application the server will execute
    attr_accessor :api

    # The plugins the server will execute
    # @return [Array] The list of plugins to be executed by the server
    attr_accessor :plugins

    # Allow to inject a custom logger
    attr_accessor :logger

    # Any additional server options
    # @return [Hash] Any options to be passed to the server
    attr_accessor :app_options

    # The parsed options
    # @return [Hash] The options parsed by the runner
    attr_reader :options

    # Create a new Goliath::Runner
    #
    # @param argv [Array] The command line arguments
    # @param api [Object | nil] The Goliath::API this runner is for, can be nil
    # @return [Goliath::Runner] An initialized Goliath::Runner
    def initialize(argv, api)
      api.options_parser(options_parser, options) if api
      options_parser.parse!(argv)

      # We've already dealt with the environment, so just discard it.
      options.delete(:env)

      @api = api
      @address = options.delete(:address)
      @port = options.delete(:port)

      @log_file = options.delete(:log_file)
      @pid_file = options.delete(:pid_file)

      @log_stdout = options.delete(:log_stdout)
      @daemonize = options.delete(:daemonize)
      @verbose = options.delete(:verbose)

      @server_options = options
    end

    # Create the options parser
    #
    # @return [OptionParser] Creates the options parser for the runner with the default options
    def options_parser
      @options ||= {
        :address => Goliath::Server::DEFAULT_ADDRESS,
        :port => Goliath::Server::DEFAULT_PORT,

        :daemonize => false,
        :verbose => false,
        :log_stdout => false,
        :env => Goliath::DEFAULT_ENV
      }

      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: <server> [options]"

        opts.separator ""
        opts.separator "Server options:"

        # The environment isn't set as part of this option parsing routine, but
        # we'll leave the flag here so a call to --help shows it correctly.
        opts.on('-e', '--environment NAME', "Set the execution environment (default: #{@options[:env]})") { |val| @options[:env] = val }

        opts.on('-a', '--address HOST', "Bind to HOST address (default: #{@options[:address]})") { |addr| @options[:address] = addr }
        opts.on('-p', '--port PORT', "Use PORT (default: #{@options[:port]})") { |port| @options[:port] = port.to_i }
        opts.on('-S', '--socket FILE', "Bind to unix domain socket") { |v| @options[:address] = v; @options[:port] = nil }
        opts.on('-E', '--einhorn', "Use Einhorn socket manager") { |v| @options[:einhorn] = true }

        opts.separator ""
        opts.separator "Daemon options:"

        opts.on('-u', '--user USER', "Run as specified user") {|v| @options[:user] = v }
        opts.on('-c', '--config FILE', "Config file (default: ./config/<server>.rb)") { |v| @options[:config] = v }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }
        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }

        opts.separator ""
        opts.separator "SSL options:"
        opts.on('--ssl', 'Enables SSL (default: off)') {|v| @options[:ssl] = v }
        opts.on('--ssl-key FILE', 'Path to private key') {|v| @options[:ssl_key] = v }
        opts.on('--ssl-cert FILE', 'Path to certificate') {|v| @options[:ssl_cert] = v }
        opts.on('--ssl-verify', 'Enables SSL certificate verification') {|v| @options[:ssl_verify] = v }

        opts.separator ""
        opts.separator "Common options:"

        opts.on('-C', '--console', 'Start a console') { @options[:console] = true }
        opts.on('-v', '--verbose', "Enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }
        opts.on('-h', '--help', 'Display help message') { show_options(opts) }
      end
    end

    # Stores the list of plugins to be used by the server
    #
    # @param plugins [Array] The list of plugins to use
    # @return [Nil]
    def load_plugins(plugins)
      @plugins = plugins
    end

    # Create environment to run the server.
    # If daemonize is set this will fork off a child and kill the runner.
    #
    # @return [Nil]
    def run
      if options[:console]
        Goliath::Console.run!(setup_server)
        return
      end

      unless Goliath.env?(:test)
        $LOADED_FEATURES.unshift(File.basename($0))
        Dir.chdir(File.expand_path(File.dirname($0)))
      end

      if @daemonize
        Process.fork do
          Process.setsid
          exit if fork

          @pid_file ||= './goliath.pid'
          @log_file ||= File.expand_path('goliath.log')
          store_pid(Process.pid)

          File.umask(0000)

          log_extension = File.extname(@log_file)
          stdout_log_file = "#{File.dirname(@log_file)}/#{File.basename(@log_file, log_extension)}_stdout#{log_extension}"

          STDIN.reopen("/dev/null")
          STDOUT.reopen(stdout_log_file, "a")
          STDERR.reopen(STDOUT)

          run_server
          remove_pid
        end
      else
        run_server
      end
    end

    private

    # Output the servers options
    #
    # @param opts [OptionsParser] The options parser
    # @return [exit] This will exit the server
    def show_options(opts)
      puts opts

      at_exit { exit! }
      exit
    end

    # Sets up the logging for the runner
    # @return [Logger] The logger object
     def setup_logger
       if logger
         warn_on_custom_logger
         return logger
       end
       log = Log4r::Logger.new('goliath')

       log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
       setup_file_logger(log, log_format) if @log_file
       setup_stdout_logger(log, log_format) if @log_stdout

       log.level = @verbose ? Log4r::DEBUG : Log4r::INFO
       log
     end

     # Sets up the Goliath server
     #
     # @param log [Logger] The logger to configure the server to log to
     # @return [Server] an instance of a Goliath server
     def setup_server(log = setup_logger)
       server = Goliath::Server.new(@address, @port)
       server.logger = log
       server.app = @app
       server.api = @api
       server.plugins = @plugins || []
       server.options = @server_options
       server
     end

     # Setup file logging
     #
     # @param log [Logger] The logger to add file logging too
     # @param log_format [Log4r::Formatter] The log format to use
     # @return [Nil]
     def setup_file_logger(log, log_format)
       FileUtils.mkdir_p(File.dirname(@log_file))

       log.add(Log4r::FileOutputter.new('fileOutput', {:filename => @log_file,
                                                       :trunc => false,
                                                       :formatter => log_format}))
     end

     # Setup stdout logging
     #
     # @param log [Logger] The logger to add stdout logging too
     # @param log_format [Log4r::Formatter] The log format to use
     # @return [Nil]
     def setup_stdout_logger(log, log_format)
       log.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
     end

     # Run the server
     #
     # @return [Nil]
     def run_server
       log = setup_logger
       log.info("Starting server on http#{ @server_options[:ssl] ? 's' : nil }://#{@address}:#{@port} in #{Goliath.env} mode. Watch out for stones.")

       server = setup_server(log)
       server.api.setup if server.api.respond_to?(:setup)
       server.start
     end

     # Store the servers pid into the @pid_file
     #
     # @param pid [Integer] The pid to store
     # @return [Nil]
     def store_pid(pid)
       FileUtils.mkdir_p(File.dirname(@pid_file))
       File.open(@pid_file, 'w') { |f| f.write(pid) }
     end

     # Remove the pid file specified by @pid_file
     #
     # @return [Nil]
     def remove_pid
       File.delete(@pid_file)
     end

     def warn_on_custom_logger
       warn "log_file option will not take effect with a custom logger" if @log_file
       warn "log_stdout option will not take effect with a custom logger" if @log_stdout
       warn "verbose option will not take effect with a custom logger" if @verbose
     end
  end
end
