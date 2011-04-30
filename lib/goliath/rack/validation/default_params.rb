module Goliath
  module Rack
    module Validation
      # A middleware to validate that a parameter always has a value
      #
      # @example
      #  use Goliath::Rack::Validation::DefaultParams, {:key => 'order', :defaults => 'pubdate'}
      #
      class DefaultParams
        # Called by the framework to create the validator
        #
        # @param app The app object
        # @param opts [Hash] The options hash
        # @option opts [String] :key The key to access in the parameters
        # @option opts :defaults The default value to assign if the key is empty or non-existant
        # @return [Goliath::Rack::Validation::DefaultParams] The validator
        def initialize(app, opts = {})
          @app = app
          @defaults = opts[:defaults]
          raise Exception.new("Must provide defaults to DefaultParams") if @defaults.nil?

          @key = opts[:key]
          raise Exception.new("must provide key to DefaultParams") if @key.nil? || @key =~ /^\s*$/
        end

        def call(env)
          if !env['params'].has_key?(@key) || env['params'][@key].nil?
            env['params'][@key] = @defaults

          elsif env['params'][@key].is_a?(Array) && env['params'][@key].empty?
            env['params'][@key] = @defaults

          elsif env['params'][@key].is_a?(String)
            if env['params'][@key] =~ /^\s*$/
              env['params'][@key] = @defaults
            end
          end

          @app.call(env)
        end
      end
    end
  end
end