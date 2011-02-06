#!/usr/bin/env ruby

$:<< '../lib' << 'lib'

require 'rubygems'

require 'goliath'
require 'goliath/plugins/latency'
require 'yajl'
# require 'json'

class Echo < Goliath::API

  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params
  use Goliath::Rack::DefaultMimeType
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render
  use Goliath::Rack::Heartbeat
  use Goliath::Rack::ValidationError

  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}

  plugin Goliath::Plugin::Latency

  def response(env)
    [200, {}, {response: env.params['echo']}]
  end
end