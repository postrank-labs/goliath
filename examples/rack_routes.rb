#!/usr/bin/env ruby
# encoding: utf-8
$:<< '../lib' << 'lib'

require 'goliath'

# Example demonstrating how to have an API acting as a router.
# RackRoutes defines multiple uris and how to map them accordingly.
# Some of these routes are redirected to other Goliath API.
#
# The reason why only the last API is being used by the Goliath Server
# is because its name matches the filename.
# All the APIs are available but by default the server will use the one
# matching the file name.

# Our custom Goliath API
class HelloWorld < Goliath::API
  def response(env)
    [200, {}, "hello world!"]
  end
end

class Bonjour < Goliath::API
  def response(env)
    [200, {}, "bonjour!"]
  end
end

class Hola < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequiredParam, {:key => "foo"}

  def response(env)
    [200, {}, "hola!"]
  end
end

class Aloha < Goliath::API
  use Goliath::Rack::Validation::RequestMethod, %w(GET)

  def response(env)
    [200, {}, "Aloha"]
  end
end

class RackRoutes < Goliath::API
  map '/version' do
    run Proc.new { |env| [200, {"Content-Type" => "text/html"}, ["Version 0.1"]] }
  end

  map "/hello_world" do
    run HelloWorld.new
  end

  map "/bonjour" do
    run Bonjour.new
  end

  map "/hola" do
    use Goliath::Rack::Validation::RequestMethod, %w(GET)
    run Hola.new
  end

  map "/aloha", Aloha

  map '/' do
    run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world, /bonjour, or /hola"]] }
  end

  # You must use either maps or response, but never both!
  def response(env)
    raise RuntimeException.new("#response is ignored when using maps, so this exception won't raise. See spec/integration/rack_routes_spec.")
  end
end
