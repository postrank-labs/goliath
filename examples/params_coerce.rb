#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'multi_json'

class CustomJSON
  def coerce(value, default)
    begin
      MultiJson.decode(value)
    rescue
      return default if default
      raise Goliath::Rack::Validation::FailedCoerce.new([400, {}, "Invalid JSON"])
    end
  end
end

class ParamsCoerce < Goliath::API
  include Goliath::Rack::Types
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::CoerceValue, :key => 'user_id', :type => Integer, :default => "admin"
  use Goliath::Rack::Validation::CoerceValue, :key => 'flag', :type => Boolean
  use Goliath::Rack::Validation::CoerceValue, :key => 'amount', :type => Float
  use Goliath::Rack::Validation::CoerceValue, :key => "json", :type => CustomJSON
  use Goliath::Rack::Validation::CoerceValue, :key => "json_default", :type => CustomJSON,
                                              :default => "nojson"

  def response(env)
    [200, {}, params.to_s]
  end
end

# Example request: http://localhost:9000/?user_id=3a&flag=0&amount=3.0&json=[1,2,3]
