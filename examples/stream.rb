#!/usr/bin/env ruby

$:<< '../lib' << 'lib'

require 'rubygems'
require 'goliath'
require 'yajl'

class Stream < Goliath::API

  # reload code on every request in dev environment
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::ValidationError    # catch and render validation errors

  use Goliath::Rack::Validation::RequestMethod, %w(GET)           # allow GET requests only

  def response(env)
    i = 0
    pt = EM.add_periodic_timer(1) do
      env.stream_send("#{i} ")
      i += 1
    end

    EM.add_timer(10) do
      pt.cancel

      env.stream_send("!! BOOM !!\n")
      env.stream_close
    end

    [200, {}, Goliath::Response::STREAMING]
  end
end
