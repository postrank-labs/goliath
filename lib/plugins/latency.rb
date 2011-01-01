module Goliath
  module Plugin
    class Latency
      def initialize(port, config, status, logger)
        @status = status
        @config = config
        @logger = logger

        @last = Time.now.to_f
      end

      def run
        EM.add_periodic_timer(1) do
          @logger.info "LATENCY: #{Time.now.to_f - @last}"
          @last = Time.now.to_f
        end
      end
    end
  end
end