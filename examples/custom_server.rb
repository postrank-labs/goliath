#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'logger'
require 'goliath'

# Example demonstrating how to use a custom rack builder with the
# Goliath server and mixing Goliath APIs with normal Rack end points.
#
# Note, that the same routing behavior is supported by Goliath, loost at
# the rack_routes.rb example to see how to define custom routes.

# Our custom Goliath API
class HelloWorld < Goliath::API
  def response(env)
    [200, {}, "hello world!"]
  end
end

# Another Goliath API
class Bonjour < Goliath::API
  def response(env)
    [200, {}, "bonjour!"]
  end
end


# Rack builder acting as a router
router = Rack::Builder.new do
  
  # Rack end point
  map '/version' do
    run Proc.new {|env| [200, {"Content-Type" => "text/html"}, ["Version 0.1"]] }
  end

  # map the /hello_world uri to our Goliath API
  map "/hello_world" do
    run HelloWorld.new
  end

  # map the /bonjour uri to our other Goliath API
  map "/bonjour" do
    run Bonjour.new
  end

  # catch the root route and return a 404
  map "/" do
    run Proc.new {|env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world or /bonjour"]] }
  end

end

# Use the Goliath API to extract the server options
Goliath::Application.options_parser.parse!(ARGV)
options =  Goliath::Application.options

# We have to start our own server since we are using a custom Rack
# builder. However using the option parser makes that trivial.
server = Goliath::Server.new(options[:address], options[:port])
server.logger = Logger.new(STDOUT)
server.app = router
puts "Starting server on: #{server.address}:#{server.port}"
server.start


at_exit do
  puts "Thanks for testing Goliath, ciao!"
  exit
end
