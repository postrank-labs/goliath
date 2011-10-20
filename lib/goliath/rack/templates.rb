require 'tilt'
require 'goliath/validation/standard_http_errors'

module Goliath
  module Rack

    # Template rendering methods. Each method takes t as a Symbol (for template
    # file lookup) or as a String (to render directly), as well as an optional
    # hashes giving additional options and local variables. It returns a String
    # with the rendered output.
    #
    # This is mostly similar to the code from Sinatra (indeed, it's stolen from
    # there). It does not compile or cache templates, and the find_template
    # method is simpler.
    #
    # @author Sinatra project -- https://github.com/sinatra/sinatra/contributors
    module Templates
      # lets us decorate the string response with a .content_type accessor
      # @private
      module ContentTyped
        attr_accessor :content_type
      end

      # Render an erb template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def erb(template, options = {}, locals = {})
        render :erb, template, options, locals
      end

      # Render an erubis template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def erubis(template, options = {}, locals = {})
        render :erubis, template, options, locals
      end

      # Render a haml template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def haml(template, options = {}, locals = {})
        render :haml, template, options, locals
      end

      # Render a sass template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def sass(template, options = {}, locals = {})
        options.merge! :layout => false, :default_content_type => :css
        render :sass, template, options, locals
      end

      # Render an scss template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def scss(template, options = {}, locals = {})
        options.merge! :layout => false, :default_content_type => :css
        render :scss, template, options, locals
      end

      # Render a less template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def less(template, options = {}, locals = {})
        options.merge! :layout => false, :default_content_type => :css
        render :less, template, options, locals
      end

      # Render a builder template
      #
      # @example
      #   # produces:
      #   #   <?xml version='1.0' encoding='UTF-8'?>
      #   #   <person>
      #   #     <name aka='Frank Sinatra'>Francis Albert Sinatra</name>
      #   #     <email>Frank Sinatra</email>
      #   #   </person>
      #   builder do |xml|
      #     xml.instruct!
      #     xml.person do
      #       xml.name "Francis Albert Sinatra", :aka => "Frank Sinatra"
      #       xml.email 'frank@capitolrecords.com'
      #     end
      #   end
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @yield block If the builder method is given a block, the block is called directly
      #   with an XmlMarkup instance and used as a template.
      # @return [String] The rendered template
      # @see #render
      def builder(template = nil, options = {}, locals = {}, &block)
        options[:default_content_type] = :xml
        render_ruby(:builder, template, options, locals, &block)
      end

      # Render a liquid template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def liquid(template, options = {}, locals = {})
        render :liquid, template, options, locals
      end

      # Render a markdown template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def markdown(template, options = {}, locals = {})
        render :markdown, template, options, locals
      end

      # Render a textile template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def textile(template, options = {}, locals = {})
        render :textile, template, options, locals
      end

      # Render an rdoc template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def rdoc(template, options = {}, locals = {})
        render :rdoc, template, options, locals
      end

      # Render a radius template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def radius(template, options = {}, locals = {})
        render :radius, template, options, locals
      end

      # Render a markaby template
      #
      # @example
      #   markaby do
      #     html do
      #       head { title "Sinatra With Markaby" }
      #       body { h1 "Markaby Is Fun!" }
      #     end
      #   end
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @yield block A block template
      # @return [String] The rendered template
      # @see #render
       def markaby(template = nil, options = {}, locals = {}, &block)
        render_ruby(:mab, template, options, locals, &block)
      end

      # Render a coffee template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def coffee(template, options = {}, locals = {})
        options.merge! :layout => false, :default_content_type => :js
        render :coffee, template, options, locals
      end

      # Render a nokogiri template
      #
      # @example
      #   # produces
      #   #   <ul>
      #   #     <li>hello</li>
      #   #     <li class="current">admin</li>
      #   #   </ul>
      #   nokogiri do |doc|
      #     doc.ul do
      #       doc.li 'hello'
      #       doc.li 'admin', :class => 'current' if current_user.is_admin?
      #     end
      #   end
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @yield block A block template
      # @return [String] The rendered template
      # @see #render
      def nokogiri(template = nil, options = {}, locals = {}, &block)
        options[:default_content_type] = :xml
        render_ruby(:nokogiri, template, options, locals, &block)
      end

      # Render a slim template
      #
      # @param template [Symbol, String] Template Path (symbol) or contents (String)
      # @param options [Hash] Rendering options -- see {#render}
      # @param locals [Hash] Template-local variables -- see {#render}
      # @return [String] The rendered template
      # @see #render
      def slim(template, options = {}, locals = {})
        render :slim, template, options, locals
      end

      # Finds template file with same name as extension
      #
      # @param views [String] The view directory
      # @param name [String] The template name
      # @param engine [String] The template type
      # @return [String | nil] Template file or nil if it doesn't exist.
      def find_template(views, name, engine)
        filename = ::File.join(views, "#{name}.#{engine}")
        File.exists?(filename) ? filename : nil
      end

      # Renders a template with the given engine. Don't call this directly --
      # call one of the sugar methods.
      #
      # @param engine [Symbol] The engine (:haml, :erb, :textile, etc) to use
      # @param template [Symbol, String] Either the name or path of the template as symbol
      #   (Use `:'subdir/myview'` for views in subdirectories), or a string that
      #   will be rendered. It looks for templates in
      #   +Goliath::Application.root_path/views+ by default. It is not as clever
      #   as Sinatra: you must name your template file template_name.engine_name
      #   -- so 'foo.markdown', not 'foo.md'.
      #
      # @param options [Hash] Options for layout
      # @option options :content_type [String] The MIME content type to use.
      # @option options [String] :layout If false, no layout is rendered, otherwise the specified layout is used.
      # @option options [String] :layout_engine  Engine to use for rendering the layout.
      # @option options [Hash] :locals A hash with local variables that should be available in the template
      # @option options [Object] :scope If set, template is evaluate with the binding of the
      #                                 given object rather than the application instance.
      # @option options [String] :views Views directory to use.
      #
      # You may set template-global defaults in config[:template], for example
      #
      #      config[:template] = {
      #        :layout_engine => :haml,
      #      }
      #
      # and engine-specific defaults in config[:template_engines], for example
      #
      #       config[:template_engines] = {
      #         :haml => {
      #           :escape_html   => true
      #         }
      #       }
      #
      # @param locals [Hash] You can give a hash of local variables available to
      #                      the template either directly in +options[:local]+ or in a
      #                      separate hash as the last parameter.
      # @return [String] The rendered template
      def render(engine, data, options = {}, locals = {}, &block)
        # merge app-level options
        if config.has_key?(:template_engines) && config[:template_engines].has_key?(engine)
          options = config[:template_engines][engine].merge(options)
        end

        options = config[:template].merge(options) if config.has_key?(:template)

        # extract generic options
        locals = options.delete(:locals) || locals || {}
        views = options.delete(:views) || Goliath::Application.root_path('views')

        default_layout  = options.delete(:default_layout) || :layout

        layout = options.delete(:layout)
        layout = default_layout if layout.nil? || layout == true

        content_type = options.delete(:content_type) || options.delete(:default_content_type)
        layout_engine = options.delete(:layout_engine) || engine
        scope = options.delete(:scope) || self

        layout_filename = find_template(views, layout, layout_engine)

        layout_template = if layout == false || layout_filename == nil
          NullLayout
        else
          Tilt.new(layout_filename, nil, options)
        end

        template_filename = find_template(views, data, engine)
        unless template_filename
          raise Goliath::Validation::InternalServerError, "Template #{data} not found in #{views} for #{engine}"
        end

        template = Tilt.new(template_filename, nil, options)
        output = layout_template.render(scope, locals) do
          template.render(scope, locals)
        end

        output.extend(ContentTyped).content_type = content_type if content_type
        output
      end

      private

      # Acts like a layout, does nothing.
      # @private
      class NullLayout
        def self.render(*args, &block)
          block.call
        end
      end

      # logic shared between builder and nokogiri
      def render_ruby(engine, template, options = {}, locals = {}, &block)
        options, template = template, nil if template.is_a?(Hash)
        template = Proc.new { block } if template.nil?

        render engine, template, options, locals
      end
    end
  end
end
