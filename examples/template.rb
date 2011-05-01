#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

# A simple dashboard for goliath
# See
#   examples/views              -- templates
#   examples/public             -- static files
#   examples/config/template.rb -- configuration
#
# The templating is based on, but not as fancy-pants as, Sinatra's. Notably,
# your template's extension must match the engine (foo.markdown, not foo.md)

require 'tilt'
# use bluecloth as default markdown renderer
require 'bluecloth'
Tilt.register 'markdown', Tilt::BlueClothTemplate
require 'yajl/json_gem'

require 'goliath'
require 'goliath/rack/templates'
require 'goliath/plugins/latency'

class Template < Goliath::API
  include Goliath::Rack::Templates      # render templated files from ./views

  use(Rack::Static,                     # render static files from ./public
            :root => Goliath::Application.app_path("public"),
            :urls => ["/favicon.ico", '/stylesheets', '/javascripts', '/images'])

  plugin Goliath::Plugin::Latency       # ask eventmachine reactor to track its latency

  def recent_latency
    Goliath::Plugin::Latency.recent_latency
  end

  def response(env)
    case env['PATH_INFO']
    when '/'         then [200, {}, haml(:root)]
    when '/debug'    then [200, {}, haml(:debug)]
    when '/oops'     then [200, {}, haml(:no_such_template)] # will 500
    when '/joke'     then
      [200, {}, markdown(:joke, :locals => {:title => "HERE IS A JOKE"})]
    when '/erb_me'   then
      [200, {}, markdown(:joke, :layout_engine => :erb, :locals => {:title => "HERE IS A JOKE"})]
    else                  raise Goliath::Validation::NotFoundError
    end
  end
end
