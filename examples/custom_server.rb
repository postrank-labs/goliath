#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath/api'
require 'goliath/runner'

# Example demonstrating how to use a custom Goliath runner
#

class Custom < Goliath::API
  def response(env)
    [200, {}, "hello!"]
  end
end

runner = Goliath::Runner.new(ARGV, nil)
runner.api = Custom.new
runner.app = Goliath::Rack::Builder.build(Custom, runner.api)
runner.run