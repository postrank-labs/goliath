#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

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

  map '/' do
    run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world or /bonjour"]] }
  end
end
