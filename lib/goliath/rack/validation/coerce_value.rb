require 'multi_json'

module Goliath
  module Rack
    module Validation
      # A middleware to coerce a given value to a given type. This will attempt to do the following
      # conversions:
      #  int | integer
      #  str | string
      #  bool | boolean = 'true' | 't' | 1 | 'false' | 'f' | 0
      #  json
      #
      # If the option default is not provided, validation_error will be returned from call(env)
      #
      # @example
      # use Goliath::Rack::Validation::CoerceValue, {:key => 'user_id', :as => :integer}
      # use Goliath::Rack::Validation::CoerceValue, {:key => 'private', :as => :boolean, :default => 0}
      #
      # It is recommended to use Goliath::Rack::Validation::RequiredParam to protect against not given
      # values.
      #
      class CoerceValue
        include Goliath::Rack::Validator
        attr_reader :key, :as, :default

        # Creates the Goliath::Rack::Validation::CoerceValue validator
        #
        # @param app The app object
        # @param opts [Hash] The validator options
        # @option opts [String] :key The key to look for in params (default: id)
        # @option opts [String | Symbol] :as The as symbol/string to coerce params[key] to. (default: string)
        # @option opts [String] :default (default: validation_error)
        # @return [Goliath::Rack::Validation::CoerceValue] The validator
        def initialize(app, opts={})
          @app = app
          @key = opts[:key] || 'id'
          @as = (opts[:as] || :string).to_sym
          @default = opts[:default]
          check_opts!
        end

        def call(env)
          begin
            env['params'][@key] = mapping[@as].call(env['params'][@key])
          rescue => e
            if !@default
              return validation_error(400, "#{@key} is not a valid #{@as}")
            else
              env['params'][@key] = @default
            end
          end
          @app.call(env)
        end

        private

        def mapping
          @_mapping ||= begin
                          mapping = {
                            :integer => proc {|val| Integer(val)},
                            :string =>  proc {|val| String(val)},
                            :boolean => proc { |val|
                            if ['true', 't'].include?(val.downcase)
                              true
                            elsif ['false', 'f'].include?(val.downcase)
                              false
                            elsif Integer(val) == 1
                              true
                            elsif Integer(val) == 0
                              false
                            else
                              raise "#{val} not boolean"
                            end
                          },
                            :json => proc {|val| MultiJson.decode(val)},
                          }

                          mapping[:int] = mapping[:integer]
                          mapping[:str] = mapping[:string]
                          mapping[:bool] = mapping[:boolean]
                          mapping
                        end
        end

        def check_opts!
          unless mapping.include?(@as)
            raise Exception.new("CoerceValue as value should be one of these: "\
                                "#{mapping.keys.join(", ")}. #{@as} is not supported.")
          end
        end
      end
    end
  end
end
