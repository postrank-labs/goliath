require 'goliath/headers'
require 'goliath/request'
require 'goliath/http_status_codes'
require 'time'

module Goliath
  class Response
    attr_accessor :status, :headers, :body

    CONNECTION = 'Connection'.freeze
    CLOSE = 'close'.freeze
    SERVER = 'Server'.freeze
    DATE = 'Date'.freeze

    def initialize
      @headers = Goliath::Headers.new
      self.status = 200
    end

    def head
      "HTTP/1.1 #{status} #{HTTP_STATUS_CODES[status.to_i]}\r\n"
    end

    def headers_output
      headers[CONNECTION] = CLOSE
      headers[SERVER] = Goliath::Request::SERVER
      headers[DATE] = Time.now.httpdate

      "#{headers.to_s}\r\n"
    end

    def headers=(key_value_pairs)
      if key_value_pairs
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
    end

    def close
      body.close if body.respond_to?(:close)
    end

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
