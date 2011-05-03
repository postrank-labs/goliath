require 'cfpropertylist'

module Goliath
  module Rack
    module Formatters
      # A plist formatter.
      #
      # @example
      #   use Goliath::Rack::Formatters::Plist
      class Plist
        include AsyncMiddleware

        def post_process(env, status, headers, body)
          if plist_response?(headers)
            body = [body.to_plist({:converter_method => :to_plist_item,:convert_unknown_to_string => true})]
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
