require 'rack'

module Goliath
  module Rack
    module Formatters
      class XML
        def initialize(app)
          @app = app
        end

        def call(env)
          async_cb = env['async.callback']
          env['async.callback'] = Proc.new do |status, headers, body|
            async_cb.call(post_process(status, headers, body))
          end

          status, headers, body = @app.call(env)
          post_process(status, headers, body)
        end

        def post_process(status, headers, body)
          if xml_response?(headers)
            body = StringIO.new(to_xml(body, false))
          end
          [status, headers, body]
        end

        def xml_response?(headers)
          headers['Content-Type'] =~ %r{^application/xml}
        end

        def to_xml(content, fragment=true, root='results', item='item')
          xml_string = ''
          xml_string += xml_header(root) unless fragment

          xml_string += case(content.class.to_s)
          when "Hash" then hash_to_xml(content, root, item)
          when "Array" then array_to_xml(content, root, item)
          when "String" then string_to_xml(content)
          else string_to_xml(content)
          end

          xml_string += xml_footer(root) unless fragment
          xml_string
        end

        def string_to_xml(content)
          ::Rack::Utils.escape_html(content.to_s)
        end

        def hash_to_xml(content, root='results', item='item')
          xml_string = ''
          if content.key?('meta')
            xml_string += xml_item('meta', content['meta'], root)
            content.delete('meta')
          end

          content.each_pair { |key, value| xml_string += xml_item(key, value, root) }
          xml_string
        end

        def array_to_xml(content, root='results', item='item')
          xml_string = ''
          content.each { |value| xml_string += xml_item(item, value, root) }
          xml_string
        end

        def xml_header(root)
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
          "<#{root} xmlns:opensearch='http://a9.com/-/spec/opensearch/1.1/'\n" +
          "         xmlns:postrank='http://www.postrank.com/xsd/2007-11-30/postrank'>\n"
        end

        def xml_footer(root)
          "</#{root}>"
        end

        def xml_item(key, value, root)
          "<#{key}>#{to_xml(value, true, root)}</#{key}>\n"
        end
      end
    end
  end
end
