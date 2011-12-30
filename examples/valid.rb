#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

class ValidSingleParam < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  # If you are using Golaith version <=0.9.1 you need to use Goliath::Rack::ValidationError
  # to prevent the request from remaining open after an error occurs
  #use Goliath::Rack::ValidationError

  def response(env)
    [200, {}, 'OK']
  end
end


class ValidNestedParams < Goliath::API
  use Goliath::Rack::Params
  
  # For this validation to pass you need to have this as parameter (json body here)
  # {
  #   'data' : {
  #     'login' : 'my_login'
  #   }
  # }
  # 
  use Goliath::Rack::Validation::RequiredParam, :key => %w(data login)
  
  def response(env)
    [200, {}, 'OK']
  end
end



class Router < Goliath::API
  map '/valid_param1', ValidSingleParam
  map '/valid_param2', ValidNestedParams
end
