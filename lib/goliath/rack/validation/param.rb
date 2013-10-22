module Goliath
  module Rack
    module Validation
      class FailedCoerce < StandardError
        attr_reader :error
        def initialize(error)
          @error = error
        end
      end

      # A middleware to validate that a given parameter is provided
      # and/or coerce a given parameter to a given type.
      #
      # By default, Goliath supports Integer, Boolean, Float and Symbol.
      # You can also create a custom coerce type by creating a
      # class that has an instance method, coerce. Example:
      #
      # class CustomJSON
      #   def coerce(value, opts={})
      #     MultiJson.load(value)
      #   end
      # end
      #
      # Where value is the value that should be coerced and
      # opts is a hash that contains two potential values:
      #
      # - default is the default value optionally specified in the middleware declaration.
      #   This means default will be nil if it was not set.
      # - message is the failure message optionally specified in the middleware declaration. This means message will be nil if it was not set.
      #
      # If default is not set, Integer, Boolean, Float and Symbol will return validation_error, otherwise params[key] will be set to default.
      #
      # If message is not set, it will have the error message of the exception caught by the coercion, otherwise the error message will be set to message.
      #
      # For your custom CoerceTypes, you can raise Goliath::Rack::Validation::FailedCoerce.new(value) where value is what will be returned from the call method.
      #
      # @example
      #  use Goliath::Rack::Validation::Param, {:key => 'mode', :type => 'Mode'}
      #  use Goliath::Rack::Validation::Param, {:key => 'data.credentials.login', :type => 'Login'}
      #  use Goliath::Rack::Validation::Param, {:key => %w(data credentials password), :type => 'Password'}
      #
      #  use Goliath::Rack::Validation::CoerceValue, :key => 'flag', :as => Goliath::Rack::Types::Boolean
      #
      #  (or include Goliath::Rack::Types to reference the types without the namespaces.)
      #
      #  include Goliath::Rack::Types
      #  use Goliath::Rack::Validation::Param, :key => 'amount', :as => Float
      class Param
        include Goliath::Rack::Validator
        include Coerce
        include Required
        UNKNOWN_OPTIONS = "Unknown options: %s"

        attr_reader :key, :type, :optional, :message, :default

        # Creates the Goliath::Rack::Validation::Param validator
        #
        # @param app The app object
        # @param opts [Hash] The validator options
        # @option opts [String] :key The key to look for in params (default: id)
        #   if the value is an array it defines path with nested keys (ex: ["data", "login"] or
        #   dot syntax: 'data.login')
        # @option opts [String] :type The type string to put in the error message. (default: :key)
        # @option opts [String] :message The message string to display after the type string. (default: 'identifier missing')
        # @option opts [Class] :as The type to coerce params[key] to. (default: String)
        # @option opts [String] :default (default: validation_error)
        #
        # @return [Goliath::Rack::Validation::Param] The validator
        def initialize(app, opts = {})
          @app = app
          @optional = opts.delete(:optional) || false
          @key = opts.delete(:key)
          raise Exception.new("key option required") unless @key

          @type = opts.delete(:type) || @key
          @message = opts.delete(:message) || 'identifier missing'
          @default = opts.delete(:default)

          coerce_setup!(opts)
          required_setup!(opts)

          raise Exception.new(UNKNOWN_OPTIONS % opts.inspect) unless opts.empty?
        end

        def call(env)
          previous_call = super
          return previous_call if previous_call

          @app.call(env)
        end

        def fetch_key(params, set_value=nil)
          key_path = Array(@key)
          current_value = params

          # check that the full path is present
          # omit the last part of the path
          val = key_path[0...-1].each do |key_part|
            # if the key is missing or is nil
            if !current_value.is_a?(Hash) || current_value[key_part].nil?
              break
            end

            current_value = current_value[key_part]
          end

          current_value[key_path[-1]] = set_value unless set_value.nil?
          val.nil? ? val : current_value[key_path[-1]]
        end
      end
    end
  end
end
