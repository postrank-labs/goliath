require 'tilt'
require 'goliath/validation/standard_http_errors'

module Goliath
  module Rack

    # Template rendering methods. Each method takes t as a Symbol (for template
    # file lookup) or as a String (to render directly), as well as an optional
    # hashes giving additional options and local variables. It returns a String
    # with the rendered output
    #
    # @param [Symbol, String] template Either the name or path of the template as symbol
    #   (Use `:'subdir/myview'` for views in subdirectories), or a string that
    #   will be rendered. It looks for templates in
    #   Goliath::Application.root_path('views') by default. It is not as clever
    #   as Sinatra: you must name your template file template_name.engine_name
    #   -- so 'foo.markdown', not 'foo.md'.
    #
    # @param [Hash] options Possible options are:
    #   :content_type   The content type to use, same arguments as content_type.
    #   :layout         If set to false, no layout is rendered, otherwise
    #                   the specified layout is used (Ignored for `sass` and `less`)
    #   :layout_engine  Engine to use for rendering the layout.
    #   :locals         A hash with local variables that should be available
    #                   in the template
    #   :scope          If set, template is evaluate with the binding of the given
    #                   object rather than the application instance.
    #   :views          Views directory to use.
    #
    #   You may set template-global defaults in config[:template], for example
    #
    #      config[:template] = {
    #        :layout_engine => :haml,
    #      }
    #
    #   and engine-specific defaults in config[:template_engines], for example
    #
    #       config[:template_engines] = {
    #         :haml => {
    #           :escape_html   => true
    #         }
    #       }
    #
    # @param [Hash] locals You can give a hash of local variables available to
    #   the template either directly in the options (options[:local]) or in a
    #   separate hash as the third parameter.
    #
    # This is mostly similar to the code from Sinatra (indeed, it's stolen from
    # there). It does not compile or cache templates, and the find_template
    # method is simpler.
    #
    # @author Sinatra project -- https://github.com/sinatra/sinatra/contributors
    module Templates
      module ContentTyped
        attr_accessor :content_type
      end

      def erb(template, options={}, locals={})
        render :erb, template, options, locals
      end

      def erubis(template, options={}, locals={})
        render :erubis, template, options, locals
      end

      def haml(template, options={}, locals={})
        render :haml, template, options, locals
      end

      def sass(template, options={}, locals={})
        options.merge! :layout => false, :default_content_type => :css
        render :sass, template, options, locals
      end

      def scss(template, options={}, locals={})
        options.merge! :layout => false, :default_content_type => :css
        render :scss, template, options, locals
      end

      def less(template, options={}, locals={})
        options.merge! :layout => false, :default_content_type => :css
        render :less, template, options, locals
      end

      def builder(template=nil, options={}, locals={}, &block)
        options[:default_content_type] = :xml
        render_ruby(:builder, template, options, locals, &block)
      end

      def liquid(template, options={}, locals={})
        render :liquid, template, options, locals
      end

      def markdown(template, options={}, locals={})
        render :markdown, template, options, locals
      end

      def textile(template, options={}, locals={})
        render :textile, template, options, locals
      end

      def rdoc(template, options={}, locals={})
        render :rdoc, template, options, locals
      end

      def radius(template, options={}, locals={})
        render :radius, template, options, locals
      end

      def markaby(template=nil, options={}, locals={}, &block)
        render_ruby(:mab, template, options, locals, &block)
      end

      def coffee(template, options={}, locals={})
        options.merge! :layout => false, :default_content_type => :js
        render :coffee, template, options, locals
      end

      def nokogiri(template=nil, options={}, locals={}, &block)
        options[:default_content_type] = :xml
        render_ruby(:nokogiri, template, options, locals, &block)
      end

      def slim(template, options={}, locals={})
        render :slim, template, options, locals
      end

      # Finds template file with same name as extension; returns nil if it
      # doesn't exist.
      def find_template(views, name, engine)
        filename = ::File.join(views, "#{name}.#{engine}")
        File.exists?(filename) ? filename : nil
      end

    private

      class NullLayout
        def self.render *args, &block
          block.call
        end
      end

      # logic shared between builder and nokogiri
      def render_ruby(engine, template, options={}, locals={}, &block)
        options, template = template, nil if template.is_a?(Hash)
        template = Proc.new { block } if template.nil?
        render engine, template, options, locals
      end

      def render(engine, data, options={}, locals={}, &block)
        # merge app-level options
        options = config[:template_engines][engine].merge(options) if config.has_key?(:template_engines) && config[:template_engines].has_key?(engine)
        options = config[:template].merge(options) if config.has_key?(:template)

        # extract generic options
        locals          = options.delete(:locals) || locals         || {}
        views           = options.delete(:views)  || Goliath::Application.root_path('views')
        #
        default_layout  = options.delete(:default_layout) || :layout
        layout          = options.delete(:layout)
        layout          = default_layout if layout.nil? or layout == true
        content_type    = options.delete(:content_type)  || options.delete(:default_content_type)
        layout_engine   = options.delete(:layout_engine) || engine
        scope           = options.delete(:scope)         || self

        layout_filename = find_template(views, layout, layout_engine)
        if layout == false || layout_filename == nil
          layout_template = NullLayout
        else
          layout_template = Tilt.new(layout_filename, nil, options)
        end
        template_filename = find_template(views, data, engine)
        # p [{:template_filename => template_filename, :views => views, :data => data, :engine => engine, :layout => layout, :layout_engine => layout_engine, :content_type => content_type, :options => options, :scope => scope, :locals => locals}]
        raise Goliath::Validation::InternalServerError, "Template #{data} not found in #{views} for #{engine}" unless template_filename

        template          = Tilt.new(template_filename, nil, options)
        output = layout_template.render(scope, locals) do
          template.render(scope, locals)
        end

        output.extend(ContentTyped).content_type = content_type if content_type
        output
      end

    end
  end
end
