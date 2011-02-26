#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath/api'
require 'goliath/runner'

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
    use ::Rack::ContentLength
    run Proc.new {|env| [200, {"Content-Type" => "text/html"}, ["Version 0.1"]] }
  end

  # map the /hello_world uri to our Goliath API
  map "/hello_world" do
    use ::Rack::ContentLength
    run HelloWorld.new
  end

  # map the /bonjour uri to our other Goliath API
  map "/bonjour" do
    use ::Rack::ContentLength
    run Bonjour.new
  end

  # catch the root route and return a 404
  map "/" do
    use ::Rack::ContentLength
    run Proc.new {|env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world or /bonjour"]] }
  end
end

runner = Goliath::Runner.new(ARGV, nil)
runner.app = router
runner.run

