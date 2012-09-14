require 'spec_helper'

class RailsStyleParams < Goliath::API
  use Goliath::Rack::PathParams, '/kittens/:name/:favourite_colour'

  def response(env)
    [200, {}, 'OK']
  end
end

describe RailsStyleParams do
  let(:err) { Proc.new { fail "API request failed" } }

  context 'a valid path' do
    it 'returns OK' do
      with_api(RailsStyleParams) do
        get_request({:path => '/kittens/ginger/blue'}, err) do |c|
          c.response.should == 'OK'
        end
      end
    end
  end

  context 'an invalid path' do
    it 'returns an error' do
      with_api(RailsStyleParams) do
        get_request({:path => '/donkeys/toothy'}, err) do |c|
          c.response.should == '[:error, "Request path does not match expected pattern: /donkeys/toothy"]'
        end
      end
    end
  end
end

