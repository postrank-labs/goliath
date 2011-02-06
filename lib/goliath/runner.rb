require 'goliath/goliath'
require 'goliath/server'
require 'optparse'
require 'log4r'

module Goliath
  class Runner
    attr_accessor :address, :port, :daemonize, :verbose, :log_stdout, :log_file, :pid_file, :app, :plugins, :app_options

    def set_options(opts)
      Goliath.env = opts.delete(:env)

      self.address = opts.delete(:address)
      self.port = opts.delete(:port)

      self.log_file = opts.delete(:log_file)
      self.pid_file = opts.delete(:pid_file)

      self.log_stdout = opts.delete(:log_stdout)
      self.daemonize = opts.delete(:daemonize)
      self.verbose = opts.delete(:verbose)

      self.app_options = opts
    end

    def load_app(&blk)
      self.app = ::Rack::Builder.app(&blk)
    end

    def load_plugins(plugins)
      self.plugins = plugins
    end

    def setup_logger
      log = Log4r::Logger.new('goliath')

      log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
      setup_file_logger(log, log_format)    if self.log_file
      setup_stdout_logger(log, log_format)  if self.log_stdout

      log.level = self.verbose ? Log4r::DEBUG : Log4r::INFO
      log
    end

    def setup_file_logger(log, log_format)
      FileUtils.mkdir_p(File.dirname(self.log_file))

      log.add(Log4r::FileOutputter.new('fileOutput', {:filename => self.log_file,
                                                      :trunc => false,
                                                      :formatter => log_format}))
    end

    def setup_stdout_logger(log, log_format)
      log.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
    end

    def run
      if self.daemonize
        Process.fork do
          Process.setsid
          exit if fork

          store_pid(Process.pid)

          Dir.chdir(File.dirname(__FILE__))
          File.umask(0000)

          stdout_log_file = "#{File.dirname(self.log_file)}/#{File.basename(self.log_file)}_stdout.log"

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

      log.info("Starting server on #{self.address}:#{self.port}. Watch out for stones.")

      server = Goliath::Server.new(self.address, self.port)
      server.logger = log
      server.app = self.app
      server.plugins = self.plugins
      server.options = self.app_options
      server.start
    end

    def store_pid(pid)
      FileUtils.mkdir_p(File.dirname(self.pid_file))
      File.open(self.pid_file, 'w') { |f| f.write(pid) }
    end
  end
end
