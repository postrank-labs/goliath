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
    EM.add_periodic_timer(1) { send(env, "#{i}"); i += 1 }
    EM.add_timer(10) { send(env, "BOOM"); close(env) }

    [200, {}, Goliath::Response::Streaming]
  end
end
