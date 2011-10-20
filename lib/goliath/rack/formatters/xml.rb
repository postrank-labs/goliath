require 'rack'

module Goliath
  module Rack
    module Formatters
      # A XML formatter. Attempts to convert your data into
      # an XML document.
      #
      # @example
      #   use Goliath::Rack::Formatters::XML
      class XML
        include Goliath::Rack::AsyncMiddleware

        def initialize(app, opts = {})
          @app = app
          @opts = opts
          @opts[:root] ||= 'results'
          @opts[:item] ||= 'item'
        end

        def post_process(env, status, headers, body)
          if xml_response?(headers)
            body = [to_xml(body)]
          end
          [status, headers, body]
        end

        def xml_response?(headers)
          headers['Content-Type'] =~ %r{^application/xml}
        end

        def to_xml(content, fragment=false)
          xml_string = ''
          xml_string << xml_header(@opts[:root]) unless fragment

          xml_string << case(content.class.to_s)
          when "Hash"   then hash_to_xml(content)
          when "Array"  then array_to_xml(content, @opts[:item])
          when "String" then string_to_xml(content)
          else string_to_xml(content)
          end

          xml_string << xml_footer(@opts[:root]) unless fragment
          xml_string
        end

        def string_to_xml(content)
          ::Rack::Utils.escape_html(content.to_s)
        end

        def hash_to_xml(content)
          xml_string = ''
          if content.key?('meta')
            xml_string += xml_item('meta', content['meta'])
            content.delete('meta')
          end

          content.each_pair { |key, value| xml_string << xml_item(key, value) }
          xml_string
        end

        def array_to_xml(content, item='item')
          xml_string = ''
          content.each { |value| xml_string << xml_item(item, value) }
          xml_string
        end

        def xml_header(root)
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<#{root}>"
        end

        def xml_footer(root)
          "</#{root}>"
        end

        def xml_item(key, value)
          "<#{key}>#{to_xml(value, true)}</#{key}>\n"
        end
      end
    end
  end
end
