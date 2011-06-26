#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

class Valid < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  # If you are using Golaith version <=0.9.1 you need to use Goliath::Rack::ValidationError
  # to prevent the request from remaining open after an error occurs
  #use Goliath::Rack::ValidationError

  def response(env)
    [200, {}, 'OK']
  end
end
