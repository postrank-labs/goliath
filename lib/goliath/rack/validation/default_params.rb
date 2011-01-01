require 'api/v3/lib/goliath/rack/validation_error'

module Goliath
  module Rack
    module Validation
      class DefaultParams
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