require 'goliath/constants'

module Goliath
  # Holds information for the current request.
  #
  # Goliath::Env also provides access to the logger, configuration information
  # and anything else set into the config data during initialization.
  class Env < Hash
    include Constants

    # Create a new Goliath::Env object
    #
    # @return [Goliath::Env] The Goliath::Env object
    def initialize
      self[SERVER_SOFTWARE]   = SERVER
      self[SERVER_NAME]       = LOCALHOST
      self[RACK_VERSION]      = RACK_VERSION_NUM
      self[RACK_ERRORS]       = STDERR
      self[RACK_MULTITHREAD]  = false
      self[RACK_MULTIPROCESS] = false
      self[RACK_RUN_ONCE]     = false

      self[:start_time] = Time.now.to_f
      self[:time] = Time.now.to_f
      self[:trace] = []
    end

    # Add a trace timer with the given name into the environment. The tracer will
    # provide information on the amount of time since the previous call to {#trace}
    # or since the Goliath::Env object was initialized.
    #
    # @example
    #   trace("initialize hash")
    #   ....
    #   trace("Do something else")
    #
    # @param name [String] The name of the trace to add
    def trace(name)
      self[:trace].push([name, "%.2f" % ((Time.now.to_f - self[:time]) * 1000)])
      self[:time] = Time.now.to_f
    end

    # Retrieve the tracer stats for this request environment. This can then be
    # returned in the headers hash to in development to provide some simple
    # timing information for the various API components.
    #
    # @example
    #   [200, {}, {:meta => {:trace => env.trace_stats}}, {}]
    #
    # @return [Array] Array of [name, time] pairs with a Total entry added.d
    def trace_stats
      self[:trace] + [['total', self[:trace].collect { |s| s[1].to_f }.inject(:+).to_s]]
    end

    # The on_close block will be executed when the connection to the client is closed.
    # This is useful in streaming servers where we may have setup an EM::Channel or some
    # timer that we need to be able to cancel.
    #
    # @example
    #  env.on_close do
    #    env.logger.info "Connection closed."
    #  end
    #
    # @param blk The block to execute.
    def on_close(&blk)
      self[ASYNC_CLOSE].callback &blk
    end

    # If the API is a streaming API this will send the provided data to the client.
    # There will be no processing done on the data when this is called so it's the
    # APIs responsibility to have the data formatted as needed.
    #
    # @param data [String] The data to send to the client.
    def stream_send(data)
      self[STREAM_SEND].call(data)
    end

    # If the API is a streaming API this will be executed by the API to signal that
    # the stream is complete. This will close the connection with the client.
    def stream_close
      self[STREAM_CLOSE].call
    end

    # @param name [Symbol] The method to check if we respond to it.
    # @return [Boolean] True if the Env responds to the method, false otherwise
    def respond_to?(name)
      return true if has_key?(name.to_s)
      return true if self['config'] && self['config'].has_key?(name.to_s)
      super
    end

    # The Goliath::Env will provide any of it's keys as a method. It will also provide
    # any of the keys in the config object as methods. The methods will return
    # the value of the key. If the key doesn't exist in either hash this will
    # fall back to the standard method_missing implementation.
    #
    # @param name [Symbol] The method to look for
    # @param args The arguments
    # @param blk A block
    def method_missing(name, *args, &blk)
      return self[name.to_s] if has_key?(name.to_s)
      return self['config'][name.to_s] if self['config'] && self['config'].has_key?(name.to_s)
      super(name, *args, &blk)
    end
  end
end
