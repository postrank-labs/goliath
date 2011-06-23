#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

#
# Example of using "config/conf_test.rb" during server initialization
#  - options parser allows us to extend the command line parameters for API
#  - config file shows loading of environment specific, global, and shared variables
#

require 'goliath'

class ConfTest < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Render, 'json'

  def options_parser(opts, options)
    options[:test] = 0
    opts.on('-t', '--test NUM', "The test number") { |val| options[:test] = val.to_i }
  end

  def response(env)
    [200, {}, {:response => env.config}]
  end
end
