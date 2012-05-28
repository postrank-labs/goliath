#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

#
# Example of using the rack/deflater middleware to automatically GZIP your response
# if the client indicated that it will accept gzipped data.
#
# Note that we're also using Rack::Rewrite to alter incoming request prior to it
# being parsed by the Rack::Params middleware. This allows us to transparently
# rewrite incoming requests before any processing is done on it.
#
# curl -s -H "Accept-Encoding: gzip,deflate" -H "Connection: close" localhost:9000?gziped=test | gunzip
#

require 'rack/deflater'
require 'rack/rewrite'
require 'goliath'
require 'yajl' if RUBY_PLATFORM != 'java'

class Gziped < Goliath::API
  # if client requested, compress the response
  use ::Rack::Deflater

  # example of using rack rewriting to rewrite the param gziped to echo
  use ::Rack::Rewrite do
    rewrite %r{^(.*?)\??gziped=(.*)$}, lambda { |match, env| "#{match[1]}?echo=#{match[2]}" }
  end

  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format

  use Goliath::Rack::Validation::RequestMethod, %w(GET)           # allow GET requests only
  use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}  # must provide ?echo= query or body param

  def response(env)
    [200, {}, {response: env.params['echo']}]
  end
end