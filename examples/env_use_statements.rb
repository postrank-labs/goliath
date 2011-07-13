#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'yajl'

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
