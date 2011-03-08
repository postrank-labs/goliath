#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

class Valid < Goliath::API

  # reload code on every request in dev environment
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params
  use Goliath::Rack::ValidationError

  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  def response(env)
    [200, {}, 'OK']
  end
end
