module Goliath
  module Rack
    module Validation
      class BooleanValue
        def initialize(app, opts = {})
          @app = app
          @key = opts[:key]
          raise Exception.new("BooleanValue key required") if @key.nil?

          @default = opts[:default]
        end

        def call(env)
          if !env['params'].has_key?(@key) || env['params'][@key].nil? || env['params'][@key] == ''
            env['params'][@key] = @default

          else
            if env['params'][@key].instance_of?(Array)
              env['params'][@key] = env['params'][@key].first
            end

            if env['params'][@key].downcase == 'true' ||
                env['params'][@key].downcase == 't' ||
                env['params'][@key].to_i == 1
              env['params'][@key] = true

            elsif env['params'][@key].downcase == 'false' ||
                env['params'][@key].downcase == 'f' ||
                env['params'][@key].to_i == 0
              env['params'][@key] = false

            else
              env['params'][@key] = @default
            end
          end

          @app.call(env)
        end
      end
    end
  end
end