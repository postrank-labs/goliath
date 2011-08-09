#!/usr/bin/env ruby
require 'time'

#
# Reads a favicon.ico statically at load time, renders it on any request for
# '/favicon.ico', and sends every other request on downstream.
#
# If you will be serving even one more file than this one, you should instead
# use Rack::Static:
#
#     use(Rack::Static, # render static files from ./public
#            :root => Goliath::Application.app_path("public"),
#            :urls => ["/favicon.ico", '/stylesheets', '/javascripts', '/images'])
#
class Favicon
  def initialize(app, filename)
    @@favicon  = File.read(filename)
    @@last_mod = File.mtime(filename).utc.rfc822
    @@expires  = Time.at(Time.now + 604800).utc.rfc822 # 1 week from now
    @app = app
  end

  def call(env, *args)
    if env['REQUEST_PATH'] == '/favicon.ico'
      return [200, {"Last-Modified"=> @@last_mod.to_s, "Expires" => @@expires, "Content-Type"=>"image/vnd.microsoft.icon"}, @@favicon]
    else
      return @app.call(env)
    end
  end
end

if File.expand_path($0) == File.expand_path(__FILE__)
  $:<< '../lib' << 'lib'
  require 'goliath'
  puts "starting hello world!"
  class HelloWorld < Goliath::API
    HelloWorld.use(Favicon, File.expand_path(File.dirname(__FILE__)+"/public/favicon.ico"))
  end
  require(File.dirname(__FILE__)+'/hello_world.rb')
end
