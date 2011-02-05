#!/usr/bin/env ruby

$:<< '../lib'

require 'rubygems'
require 'goliath'

class ConfTest < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render

  def options_parser(opts, options)
    options[:test] = 0
    opts.on('-t', '--test NUM', "The test number") { |val| options[:test] = val.to_i }
  end

  def response(env)
    [200, {}, {:response => env.config}]
  end
end
