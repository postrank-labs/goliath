#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath/api'
require 'goliath/runner'

# Example demonstrating how to use a custom Goliath runner
#

class Hello < Goliath::API
  def response(env)
    [200, {}, "hello!"]
  end
end

class Bonjour < Goliath::API
  def response(env)
    [200, {}, "bonjour!"]
  end
end

class Custom < Goliath::API
  map "/hello", Hello
  map "/bonjour", Bonjour
end

runner = Goliath::Runner.new(ARGV, nil)
runner.api = Custom.new
runner.app = Goliath::Rack::Builder.build(Custom, runner.api)
runner.run