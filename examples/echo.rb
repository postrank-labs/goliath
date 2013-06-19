#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'goliath/plugins/latency'

# Goliath uses multi-json, so pick your favorite JSON serializer
# require 'json'
require 'yajl' if RUBY_PLATFORM != 'java'

class Echo < Goliath::API
  use Goliath::Rack::Tracer             # log trace statistics
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)

  # If you are using Golaith version <=0.9.1 you need to Goliath::Rack::ValidationError
  # to prevent the request from remaining open after an error occurs
  #use Goliath::Rack::ValidationError
  use Goliath::Rack::Validation::RequestMethod, %w(GET POST PATCH) # allow GET, POST and PATCH requests only
  use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}  # must provide ?echo= query or body param

  plugin Goliath::Plugin::Latency       # output reactor latency every second

  def process_request
    logger.info "Processing request"

    {response: env.params['echo']}
  end

  def response(env)
    [200, {}, process_request]
  end
end
