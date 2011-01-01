require 'goliath/rack/validation_error'

module Goliath
  module Rack
    module Validation
      class RequiredParam
        attr_reader :type, :key

        def initialize(app, opts = {})
          @app = app
          @type = opts[:type] || 'Feed'
          @key = opts[:key] || 'id'
        end

        def call(env)
          key_valid!(env['params'])
          @app.call(env)
        end

        def key_valid!(params)
          error = false
          if !params.has_key?(key) || params[key].nil? ||
              (params[key].is_a?(String) && params[key] =~ /^\s*$/)
            error = true
          end

          if params[key].is_a?(Array)
            unless params[key].compact.empty?
              params[key].each do |k|
                return unless k.is_a?(String)
                return unless k =~ /^\s*$/
              end
            end
            error = true
          end

          raise Goliath::Validation::Error.new(400, "#{@type} identifier missing") if error
        end
      end
    end
  end
end