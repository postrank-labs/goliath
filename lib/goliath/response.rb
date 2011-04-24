require 'goliath/headers'
require 'goliath/request'
require 'goliath/http_status_codes'
require 'time'

module Goliath
  # Goliath::Response holds the information that will be sent back
  # to the client.
  #
  # @private
  class Response
    # The status code to send
    attr_accessor :status

    # The headers to send
    attr_accessor :headers

    # The body to send
    attr_accessor :body

    SERVER = 'Server'
    DATE = 'Date'

    # Used to signal that a response is a streaming response
    STREAMING = :goliath_stream_response
    CHUNKED_STREAM_HEADERS = { 'Transfer-Encoding' => 'chunked' }

    def initialize
      @headers = Goliath::Headers.new
      @status = 200
    end

    # Creates the header line for the response
    #
    # @return [String] The HTTP header line
    def head
      "HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status.to_i]}\r\n"
    end

    # Creats the headers to be returned to the client
    #
    # @return [String] The HTTP headers
    def headers_output
      headers[SERVER] = Goliath::Request::SERVER
      headers[DATE] = Time.now.httpdate

      "#{headers.to_s}\r\n"
    end

    # Sets a set of key value pairs into the headers
    #
    # @param key_value_pairs [Hash] The key/value pairs to set as headers
    # @return [Nil]
    def headers=(key_value_pairs)
      return unless key_value_pairs

      key_value_pairs.each do |k, vs|
        next unless vs

        if vs.is_a?(String)
          vs.each_line { |v| @headers[k] = v.chomp }

        elsif vs.is_a?(Time)
          @headers[k] = vs

        else
          vs.each { |v| @headers[k] = v.chomp }
        end
      end
    end

    # Used to signal that the response is closed
    #
    # @return [Nil]
    def close
      body.close if body.respond_to?(:close)
    end

    # Yields each portion of the response
    #
    # @yield [String] The header line, headers and body content
    # @return [Nil]
    def each
      yield head
      yield headers_output

      if body.respond_to?(:each)
        body.each { |chunk| yield chunk }
      else
        yield body
      end
    end
  end
end
