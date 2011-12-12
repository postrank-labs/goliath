module Goliath
  module Rack
    module Validation
      class FailedCoerce < StandardError
        attr_reader :error
        def initialize(error)
          @error = error
        end
      end

      # A middleware to coerce a given value to a given type. By default, Goliath supports Integer, Boolean, String, Float and Symbol. You can also create a custom coerce type by simply create a class that has an instance method, coerce. An example would be:
      #
      # class CustomJSON
      #   def coerce(value, default)
      #     MultiJson.decode(value)
      #   end
      # end
      #
      # Where value is the value that should be coerced and default is the default value optionally specified in the middleware declaration. This means default will be nil if it was not set.
      #
      # If default is not set, Integer, Boolean, String, Float and Symbol will return validation_error, otherwise params[key] will be set to default.
      #
      # For your custom CoerceTypes, you can raise Goliath::Rack::Validation::FailedCoerce.new(value) where value is what will be returned from the call method.
      #
      # @example
      # use Goliath::Rack::Validation::CoerceValue, :key => 'flag', :type => Goliath::Rack::Types::Boolean
      #
      # (or include Goliath::Rack::Types to reference the types without the namespaces.)
      #
      # include Goliath::Rack::Types
      # use Goliath::Rack::Validation::CoerceValue, :key => 'user_id', :type => Integer, :default => "admin"
      #
      #
      # It is recommended to use Goliath::Rack::Validation::RequiredParam to protect against not given
      # values.
      #
      class CoerceValue
        include Goliath::Rack::Validator
        attr_reader :key, :type, :default

        # Creates the Goliath::Rack::Validation::CoerceValue validator
        #
        # @param app The app object
        # @param opts [Hash] The validator options
        # @option opts [String] :key The key to look for in params (default: id)
        # @option opts [String | Symbol] :type The type to coerce params[key] to. (default: String)
        # @option opts [String] :default (default: validation_error)
        # @return [Goliath::Rack::Validation::CoerceValue] The validator
        def initialize(app, opts={})
          @app = app
          @key = opts[:key] || 'id'
          @type = opts[:type] || Goliath::Rack::Types::String
          @type_instance = @type.new
          unless @type_instance.respond_to?(:coerce)
            raise Exception.new("#{@type_instance} does not respond to coerce")
          end
          @default = opts[:default]
        end

        def call(env)
          begin
            env['params'][@key] = @type_instance.coerce(env['params'][@key], @default)
          rescue FailedCoerce => e
            return e.error
          end
          @app.call(env)
        end
      end
    end
  end
end
