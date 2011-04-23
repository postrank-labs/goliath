module Goliath
  module Plugin
    # Report latency information about the EventMachine reactor to the log file.
    #
    # @example
    #  plugin Goliath::Plugin::Latency
    #
    class Latency
      # Called by the framework to initialize the plugin
      #
      # @param port [Integer] Unused
      # @param config [Hash] The server configuration data
      # @param status [Hash] A status hash
      # @param logger [Log4R::Logger] The logger
      # @return [Goliath::Plugin::Latency] An instance of the Goliath::Plugin::Latency plugin
      def initialize(port, config, status, logger)
        @status = status
        @config = config
        @logger = logger

        @last = Time.now.to_f
      end

      @@recent_latency = 0
      def self.recent_latency
        @@recent_latency
      end

      # Called automatically to start the plugin
      def run
        EM.add_periodic_timer(1) do
          @@recent_latency = (Time.now.to_f - @last)
          @logger.info "LATENCY: #{@@recent_latency}"
          @last = Time.now.to_f
        end
      end
    end
  end
end
