#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'yajl'

# API must be started with -e [production, development, ...]
# or set your ENV['RACK_ENV'] to specify the environemtn

class EnvUseStatements < Goliath::API
  if Goliath.dev?
    use Goliath::Rack::Render, 'json'
  elsif Goliath.prod?
    use Goliath::Rack::Render, 'xml'
  end

  def response(env)
    [200, {}, {'Test' => 'Response'}]
  end
end
