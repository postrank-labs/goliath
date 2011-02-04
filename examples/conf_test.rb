#!/usr/bin/env ruby

require 'rubygems'
require 'goliath'

class ConfTest < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render

  def response(env)
    [200, {}, {:response => env.config}]
  end
end
