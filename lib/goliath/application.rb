# Most of this stuff is straight out of sinatra.
module Goliath
  class Application
    CALLERS_TO_IGNORE = [ # :nodoc:
      /\/goliath(\/(application))?\.rb$/, # all goliath code
      /rubygems\/custom_require\.rb$/,    # rubygems require hacks
      /bundler(\/runtime)?\.rb/,          # bundler require hacks
      /<internal:/                        # internal in ruby >= 1.9.2
    ]

    # add rubinius (and hopefully other VM impls) ignore patterns ...
    CALLERS_TO_IGNORE.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

    # Like Kernel#caller but excluding certain magic entries and without
    # line / method information; the resulting array contains filenames only.
    def self.caller_files
      caller_locations.map { |file, line| file }
    end

    # Like caller_files, but containing Arrays rather than strings with the
    # first element being the file, and the second being the line.
    def self.caller_locations
      caller(1).
        map    { |line| line.split(/:(?=\d|in )/)[0,2] }.
        reject { |file, line| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
    end

    def self.app_file
      c = caller_files.first
      c = $0 if !c || c.empty?
      c
    end

    def self.options_parser
      @options ||= {
        :address => Goliath::Server::DEFAULT_ADDRESS,
        :port => Goliath::Server::DEFAULT_PORT,

        :daemonize => false,
        :verbose => false,
        :log_stdout => false
      }

      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{app_file} [options]"

        opts.separator ""
        opts.separator "Server options:"

        opts.on('-e', '--environment NAME', "Set the execution environment (prod, dev or test) (default: #{Goliath.env})") { |val| @options[:env] = val }

        opts.on('-a', '--address HOST', "Bind to HOST address (default: #{@options[:address]})") { |addr| @options[:address] = addr }
        opts.on('-p', '--port PORT', "Use PORT (default: #{@options[:port]})") { |port| @options[:port] = port.to_i }

        opts.on('-l', '--log FILE', "Log to file (default: off)") { |file| @options[:log_file] = file }
        opts.on('-s', '--stdout', "Log to stdout (default: #{@options[:log_stdout]})") { |v| @options[:log_stdout] = v }

        opts.on('-P', '--pid FILE', "Pid file (default: off)") { |file| @options[:pid_file] = file }
        opts.on('-d', '--daemonize', "Run daemonized in the background (default: #{@options[:daemonize]})") { |v| @options[:daemonize] = v }
        opts.on('-v', '--verbose', "Enable verbose logging (default: #{@options[:verbose]})") { |v| @options[:verbose] = v }

        opts.on('-h', '--help', 'Display help message') { show_options(opts) }
      end
    end

    def self.show_options(opts)
      puts opts

      at_exit { exit! }
      exit
    end

    def self.camel_case(str)
      return str if str !~ /_/ && str =~ /[A-Z]+.*/

      str.split('_').map { |e| e.capitalize }.join
    end

    def self.run!
      file = File.basename(app_file, '.rb')
      klass = Kernel.const_get(camel_case(file))
      app = klass.new

      runner = Goliath::Runner.new

      opts_parser = options_parser
      app.options_parser(opts_parser, @options)
      opts_parser.parse!(ARGV)
      runner.set_options(@options)

      runner.load_app do
        klass.middlewares.each do |mw|
          use(*(mw[0..1].compact), &mw[2])
        end
        run app
      end

      runner.load_plugins(klass.plugins)
      runner.run
    end
  end

  at_exit do
    if $!.nil? && $0 == Goliath::Application.app_file
      Application.run!
    end
  end
end
