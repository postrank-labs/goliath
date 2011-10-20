module Goliath
  # @private
  class Headers
    HEADER_FORMAT      = "%s: %s\r\n"
    ALLOWED_DUPLICATES = %w(Set-Cookie Set-Cookie2 Warning WWW-Authenticate)

    def initialize
      @sent = {}
      @out = []
    end

    def []=(key, value)
      return if @sent.has_key?(key) && !(ALLOWED_DUPLICATES.include?(key))

      value = case value
        when Time then value.httpdate
        when NilClass then return
        else value.to_s
      end

      @sent[key] = value
      @out << HEADER_FORMAT % [key, value]
    end

    def [](key)
      @sent[key]
    end

    def has_key?(key)
      @sent[key] ? true : false
    end

    def to_s
      @out.join
    end
  end
end
