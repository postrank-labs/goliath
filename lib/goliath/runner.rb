require 'goliath/goliath'
require 'goliath/server'
require 'optparse'
require 'log4r'

module Goliath
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
      Goliath.env = options.delete(:env)

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
        :env => :development,
      }

      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: <server> [options]"

        opts.separator ""
        opts.separator "Server options:"

        opts.on('-e', '--environment NAME', "Set the execution environment (prod, dev or test) (default: #{@options[:env]})") { |val| @options[:env] = val }

        opts.on('-a', '--address HOST', "Bind to HOST address (default: #{@options[:address]})") { |addr| @options[:address] = addr }
        opts.on('-p', '--port PORT', "Use PORT (default: #{@options[:port]})") { |port| @options[:port] = port.to_i }

        opts.on('-u', '--user USER', "Run as specified user") {|v| @options[:user] = v }
        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }

        opts.on('-c', '--config FILE', "Config file (default: ./config/<server>.rb)") { |v| @options[:config] = v }
        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
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
      unless Goliath.test?
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

          stdout_log_file = "#{File.dirname(@log_file)}/#{File.basename(@log_file)}_stdout.log"

          STDIN.reopen("/dev/null")
          STDOUT.reopen(stdout_log_file, "a")
          STDERR.reopen(STDOUT)

          run_server
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
       log = Log4r::Logger.new('goliath')

       log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
       setup_file_logger(log, log_format) if @log_file
       setup_stdout_logger(log, log_format) if @log_stdout

       log.level = @verbose ? Log4r::DEBUG : Log4r::INFO
       log
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

       log.info("Starting server on #{@address}:#{@port} in #{Goliath.env} mode. Watch out for stones.")

       server = Goliath::Server.new(@address, @port)
       server.logger = log
       server.app = @app
       server.api = @api
       server.plugins = @plugins || []
       server.options = @server_options
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
  end
end
