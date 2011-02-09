#!/usr/bin/env ruby

# curl -s -H "Accept-Encoding: gzip,deflate" localhost:9000?gziped=test |gunzip

$:<< '../lib' << 'lib'

require 'rubygems'

require 'rack/deflater'
require 'rack/rewrite'

require 'goliath'

require 'yajl'

class Gziped < Goliath::API
  # reload code on every request in dev environment
  use ::Rack::Reloader, 0 if Goliath.dev?

  # if client requested, compress the response
  use ::Rack::Deflater

  # example of using rack rewriting to rewrite the param gziped to echo
  use ::Rack::Rewrite do
    rewrite %r{^(.*?)\??gziped=(.*)$}, lambda { |match, env| "#{match[1]}?echo=#{match[2]}" }
  end

  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::ValidationError    # catch and render validation errors

  use Goliath::Rack::Validation::RequestMethod, %w(GET)           # allow GET requests only
  use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}  # must provide ?echo= query or body param

  def response(env)
    [200, {}, {response: env.params['echo']}]
  end
end