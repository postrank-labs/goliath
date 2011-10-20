require 'goliath/validation/error'
require 'goliath/http_status_codes'

module Goliath
  #
  # Make a subclass of Goliath::Validation::Error for each standard HTTP error
  # code (4xx and 5xx). Error will have a default status_code and message
  # correct for that response:
  #
  #     err = Goliath::Validation::NotFoundError.new
  #     p [err.status_code, err.to_s]
  #     # => [400, "Not Found"]
  #
  # Each class is named for the standard HTTP message, so 504 'Gateway Time-out'
  # becomes a Goliath::Validation::GatewayTimeoutError (except 'Internal Server
  # Error', which becomes InternalServerError not InternalServerErrorError). All non-alphanumeric
  # characters are smushed together, with no upcasing or
  # downcasing.
  HTTP_ERROR_CODES = HTTP_STATUS_CODES.select { |code,msg| code >= 400 && code <= 599 }

  HTTP_ERROR_CODES.each do |code, msg|
    klass_name = "#{msg.gsub(/\W+/, '')}Error".gsub(/ErrorError$/, "Error")
    klass = Class.new(Goliath::Validation::Error)
    klass.class_eval(%Q{
      def initialize(message='#{msg}')
        super('#{code}', message)
      end }, __FILE__, __LINE__)

    Goliath::Validation.const_set(klass_name, klass)
  end
end
