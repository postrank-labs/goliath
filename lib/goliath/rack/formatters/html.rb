require 'rack'

module Goliath
  module Rack
    module Formatters
      # A simple HTML formatter. This doesn't try to be fancy and just turns
      # Hashes into tables, Arrays into ordered lists and strings are output
      # as HTML escaped strings.
      #
      # @example
      #   use Goliath::Rack::Formatters::HTML
      class HTML
        include Goliath::Rack::AsyncMiddleware

        def post_process(env, status, headers, body)
          body = [to_html(body, false)] if html_response?(headers)
          [status, headers, body]
        end

        def html_response?(headers)
          headers['Content-Type'] =~ %r{^text/html}
        end

        def to_html(content, fragment=true)
          html_string = ''
          html_string += html_header unless fragment

          html_string += case(content.class.to_s)
          when "Hash" then hash_to_html(content)
          when "Array" then array_to_html(content)
          when "String" then string_to_html(content)
          else string_to_html(content)
          end

          html_string += html_footer unless fragment
          html_string
        end

        def string_to_html(content)
          ::Rack::Utils.escape_html(content.to_s)
        end

        def hash_to_html(content)
          html_string = "<table>\n"
          if content.key?('meta')
            html_string += "<tr><td>meta</td><td>\n"
            html_string += to_html(content['meta'])
            html_string += "</td></tr>\n"
            content.delete('meta')
          end

          content.each_pair { |key, value| html_string += "<tr><td>#{to_html(key)}</td><td>#{to_html(value)}</td></tr>\n" }
          html_string += "</table>\n"
          html_string
        end

        def array_to_html(content)
          html_string = '<ol>\n'
          content.each { |value| html_string += "<li>#{to_html(value)}</li>\n" }
          html_string +="</ol>\n"
          html_string
        end

        def html_header
          "<html><body>"
        end

        def html_footer
          "</body></html>"
        end
      end
    end
  end
end
