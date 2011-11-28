#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'yajl'

class Base < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Render, 'json'

  def response(env)
    [200, {}, {:p => params}]
  end
end

class Extend < Base
  def response(env)
    [200, {}, params]
  end
end

class Router < Goliath::API
  map '/base', Base
  map '/extend', Extend
end
