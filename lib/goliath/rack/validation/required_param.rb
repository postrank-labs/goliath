require 'goliath/rack/validator'

module Goliath
  module Rack
    module Validation
      # A middleware to validate that a given parameter is provided.
      #
      # @example
      #  use Goliath::Rack::Validation::RequiredParam, {:key => 'mode', :type => 'Mode'}
      #
      class RequiredParam
        include Goliath::Rack::Validator
        attr_reader :type, :key, :message

        # Creates the Goliath::Rack::Validation::RequiredParam validator
        #
        # @param app The app object
        # @param opts [Hash] The validator options
        # @option opts [String] :key The key to look for in params (default: id)
        # @option opts [String] :type The type string to put in the error message. (default: :key)
        # @option opts [String] :message The message string to display after the type string. (default: 'identifier missing')
        # @return [Goliath::Rack::Validation::RequiredParam] The validator
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key] || 'id'
          @type = opts[:type] || @key.capitalize
          @message = opts[:message] || 'identifier missing'
        end

        def call(env)
          return validation_error(400, "#{@type} #{@message}") unless key_valid?(env['params'])
          @app.call(env)
        end

        def key_valid?(params)
          if !params.has_key?(key) || params[key].nil? ||
              (params[key].is_a?(String) && params[key] =~ /^\s*$/)
            return false
          end

          if params[key].is_a?(Array)
            unless params[key].compact.empty?
              params[key].each do |k|
                return true unless k.is_a?(String)
                return true unless k =~ /^\s*$/
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
