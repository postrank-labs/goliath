require 'goliath/goliath'
require 'goliath/server'
require 'optparse'
require 'log4r'

module Goliath
  # @private
  class Runner
    attr_accessor :address, :port, :daemonize, :verbose, :log_stdout, :log_file, :pid_file, :app, :plugins, :app_options

    def set_options(opts)
      Goliath.env = opts.delete(:env)

      @address = opts.delete(:address)
      @port = opts.delete(:port)

      @log_file = opts.delete(:log_file)
      @pid_file = opts.delete(:pid_file)

      @log_stdout = opts.delete(:log_stdout)
      @daemonize = opts.delete(:daemonize)
      @verbose = opts.delete(:verbose)

      @app_options = opts
    end

    def load_app(&blk)
      @app = ::Rack::Builder.app(&blk)
    end

    def load_plugins(plugins)
      @plugins = plugins
    end

    def setup_logger
      log = Log4r::Logger.new('goliath')

      log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
      setup_file_logger(log, log_format) if @log_file
      setup_stdout_logger(log, log_format) if @log_stdout

      log.level = @verbose ? Log4r::DEBUG : Log4r::INFO
      log
    end

    def setup_file_logger(log, log_format)
      FileUtils.mkdir_p(File.dirname(@log_file))

      log.add(Log4r::FileOutputter.new('fileOutput', {:filename => @log_file,
                                                      :trunc => false,
                                                      :formatter => log_format}))
    end

    def setup_stdout_logger(log, log_format)
      log.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
    end

    def run
      if @daemonize
        Process.fork do
          Process.setsid
          exit if fork

          @pid_file ||= './goliath.pid'
          @log_file ||= File.expand_path('goliath.log')
          store_pid(Process.pid)

          Dir.chdir(File.dirname(__FILE__))
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

    def run_server
      log = setup_logger

      log.info("Starting server on #{@address}:#{@port} in #{Goliath.env} mode. Watch out for stones.")

      server = Goliath::Server.new(@address, @port)
      server.logger = log
      server.app = @app
      server.plugins = @plugins
      server.options = @app_options
      server.start
    end

    def store_pid(pid)
      FileUtils.mkdir_p(File.dirname(@pid_file))
      File.open(@pid_file, 'w') { |f| f.write(pid) }
    end
  end
end
