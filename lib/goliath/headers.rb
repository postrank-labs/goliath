require 'goliath/constants'

module Goliath
  # @private
  class Headers
    include Constants

    def initialize
      @sent = {}
      @out = []
    end

    def []=(key, value)
      return if @sent.has_key?(key) && !(ALLOWED_DUPLICATES.include?(key))

      value = case value
        when Time then value.httpdate
        when NilClass then return unless key == SERVER_HEADER
        else value.to_s
      end

      @sent[key] = value
      @out << HEADER_FORMAT % [key, value] unless value.nil?
    end

    def [](key)
      @sent[key]
    end

    def has_key?(key)
      if key == SERVER_HEADER
        @sent.has_key?(SERVER_HEADER)
      else
        @sent[key] ? true : false
      end
    end

    def to_s
      @out.join
    end
  end
end
