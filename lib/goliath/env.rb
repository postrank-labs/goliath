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
    # @return [Array] Array of [name, time] pairs with a Total entry added.
    def trace_stats
      self[:trace] + [['total', self[:trace].collect { |s| s[1].to_f }.inject(:+).to_s]]
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

    # Sends a chunk in a Chunked transfer encoding stream.
    #
    #     Each chunk starts with the number of octets of the data it embeds expressed
    #     in hexadecimal followed by optional parameters (chunk extension) and a
    #     terminating CRLF (carriage return and line feed) sequence, followed by the
    #     chunk data. The chunk is terminated by CRLF. If chunk extensions are
    #     provided, the chunk size is terminated by a semicolon followed with the
    #     extension name and an optional equal sign and value
    #
    # Note: chunk extensions aren't provided yet
    #
    # This will do nothing if the chunk is empty -- sending a zero-length chunk
    # signals the end of a stream.
    #
    def chunked_stream_send(chunk)
      return if chunk.empty?
      chunk_len_in_hex = chunk.bytesize.to_s(16)
      body = [chunk_len_in_hex, "\r\n", chunk, "\r\n"].join
      stream_send(body)
    end

    # Sends the terminating chunk in a chunked transfer encoding stream, and
    # closes the stream.
    #
    #     The last chunk is a zero-length chunk, with the chunk size coded as 0, but
    #     without any chunk data section.  The final chunk may be followed by an
    #     optional trailer of additional entity header fields that are normally
    #     delivered in the HTTP header to allow the delivery of data that can only
    #     be computed after all chunk data has been generated. The sender may
    #     indicate in a Trailer header field which additional fields it will send
    #     in the trailer after the chunks.
    #
    # Note: trailer headers aren't provided yet
    #
    def chunked_stream_close
      stream_send([0, "\r\n", "\r\n"].join)
      stream_close
    end

    # Convenience method for accessing the rack.logger item in the environment.
    #
    # @return [Logger] The logger object
    def logger
      self[RACK_LOGGER]
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
