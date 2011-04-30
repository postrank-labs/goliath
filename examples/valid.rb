#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

class Valid < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  def response(env)
    [200, {}, 'OK']
  end
end
