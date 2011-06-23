module Goliath
  module Rack
    module Formatters
      # A plist formatter. Pass in to_plist options as an option to the middleware
      #
      # @example
      #   use Goliath::Rack::Formatters::PLIST, :convert_unknown_to_string => true
      class PLIST
        include AsyncMiddleware

        def initialize(app, opts = {})
          unless Hash.new.respond_to? :to_plist
            fail "Please require a plist library that adds a to_plist method"
          end
          @app = app
          @opts = opts
        end

        def post_process(env, status, headers, body)
          if plist_response?(headers)
            body = [body.to_plist(@opts)]
          end
          [status, headers, body]
        end

        def plist_response?(headers)
          headers['Content-Type'] =~ %r{^application/x-plist}
        end
      end
    end
  end
end
