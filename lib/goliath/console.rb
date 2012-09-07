module Goliath
  # The console execution class for Goliath. This will load a REPL inside of a
  # running reactor with the associated Goliath config loaded.
  #
  # @private
  class Console
    # Starts the reactor and the REPL.
    #
    # @return [Nil]
    def self.run!(server)
      require 'irb'
      EM.synchrony do
        server.load_config
        Object.send(:define_method, :goliath_server) { server }
        IRB.start
        EM.stop
      end
    end
  end
end
