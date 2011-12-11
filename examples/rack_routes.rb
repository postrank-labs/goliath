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

class PostHelloWorld < Goliath::API
  def response(env)
    [200, {}, "hello post world!"]
  end
end

class HeaderCollector < Goliath::API
  def on_headers(env, header)
    @headers ||= {}
    @headers.merge!(header)
  end

  def response(env)
    [200, {}, "headers: #{@headers.inspect}"]
  end
end

class HelloNumber < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    [200, {}, "number #{params[:number]}!"]
  end
end

class BigNumber < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    [200, {}, "big number #{params[:number]}!"]
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

class Version < Goliath::API
  def response(env)
    [200, {"Content-Type" => "text/html"}, ["Version 0.1"]]
  end
end

class SayMyName < Goliath::API  
  def response(env)
    [200, {}, ["Hello #{@opts[:name]}"]]
  end
end


class RackRoutes < Goliath::API

  # map Goliath API to a specific path
  get  "/hello_world", HelloWorld
  head "/hello_world", HelloWorld
  post "/hello_world", PostHelloWorld

  map "/bonjour", Bonjour
  map "/aloha", Aloha
  
  get '/name1', SayMyName, :api_options => {:name => "Leonard"}
  get '/name2', SayMyName, :api_options => {:name => "Helena"}

  # map Goliath API to a specific path and inject validation middleware
  # for this route only in addition to the middleware specified by the
  # API class itself
  map "/headers", HeaderCollector do
    use Goliath::Rack::Validation::RequestMethod, %w(GET)
  end

  map "/hola", Hola do
    use Goliath::Rack::Validation::RequestMethod, %w(GET)
  end

  # bad route: you cannot run arbitrary procs or classes, please provide
  # an implementation of the Goliath API
  map "/bad_route", Hola do
    run Hola.new
  end

  not_found('/') do
    run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world, /bonjour, or /hola"]] }
  end

  # You must use either maps or response, but never both!
  def response(env)
    raise RuntimeException.new("#response is ignored when using maps, so this exception won't raise. See spec/integration/rack_routes_spec.")
  end

end
