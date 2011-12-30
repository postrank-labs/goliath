require 'goliath/rack/validator'

module Goliath
  module Rack
    module Validation
      # A middleware to validate that a given parameter is provided.
      #
      # @example
      #  use Goliath::Rack::Validation::RequiredParam, {:key => 'mode', :type => 'Mode'}
      #  use Goliath::Rack::Validation::RequiredParam, {:key => 'data.credentials.login', :type => 'Login'}
      #  use Goliath::Rack::Validation::RequiredParam, {:key => %w(data credentials password), :type => 'Password'}
      #
      class RequiredParam
        include Goliath::Rack::Validator
        attr_reader :type, :key, :message

        # extracted from activesupport 3.0.9
        NON_WHITESPACE_REGEXP = %r![^[:space:]]!

        # Creates the Goliath::Rack::Validation::RequiredParam validator
        #
        # @param app The app object
        # @param opts [Hash] The validator options
        # @option opts [String] :key The key to look for in params (default: id)
        #   if the value is an array it defines path with nested keys (ex: ["data", "login"] or
        #   dot syntax: 'data.login')
        # @option opts [String] :type The type string to put in the error message. (default: :key)
        # @option opts [String] :message The message string to display after the type string. (default: 'identifier missing')
        # @return [Goliath::Rack::Validation::RequiredParam] The validator
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key] || 'id'
          @type = opts[:type] || @key
          @message = opts[:message] || 'identifier missing'

          if @key.is_a?(String) && @key.include?('.')
            @key = @key.split('.')
          end
        end

        def call(env)
          return validation_error(400, "#{@type} #{@message}") unless key_valid?(env['params'])
          @app.call(env)
        end

        def key_valid?(params)
          key_path = Array(@key)
          current_value = params

          # check that the full path is present
          # omit the last part of the path
          key_path[0...-1].each do |key_part|
            # if the key is missing or is nil the validation failed
            if !current_value.is_a?(Hash) || current_value[key_part].nil?
              return false
            end

            current_value = current_value[key_part]
          end

          # if we are here the full path is available, now test the real key
          val = current_value[key_path[-1]]

          case val
          when nil
            return false

          when String
            # if val is a string it must not be empty
            return false if val !~ NON_WHITESPACE_REGEXP

          when Array
            unless val.compact.empty?
               val.each do |k|
                 return true unless k.is_a?(String)
                 return true unless k !~ NON_WHITESPACE_REGEXP
               end
             end

            return false
          end

          true
        end
      end
    end
  end
end
