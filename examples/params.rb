#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'multi_json'

class CustomJSON
  def coerce(value, opts={})
    begin
      MultiJson.load(value)
    rescue
      return opts[:default] if opts[:default]
      raise Goliath::Rack::Validation::FailedCoerce.new([400, {}, "Invalid JSON"])
    end
  end
end

class ParamsCoerce < Goliath::API
  include Goliath::Rack::Types
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::Param, :key => 'user_id', :as => Integer, :default => "admin"
  use Goliath::Rack::Validation::Param, :key => 'flag', :as => Boolean, :message => "Flag needs to be a boolean"
  use Goliath::Rack::Validation::Param, :key => 'amount', :as => Float
  use Goliath::Rack::Validation::Param, :key => "json", :as => CustomJSON
  use Goliath::Rack::Validation::Param, :key => "json_default", :as => CustomJSON,
                                              :default => "nojson", :optional => true

  use Goliath::Rack::Validation::Param, :key => 'name', :type => "Big Name", :message => "cant be found"

  def response(env)
    [200, {}, params.to_s]
  end
end

# Example request: http://localhost:9000/?user_id=3d&flag=1&amount=3.0&json=[1,2,3]&name=mike

