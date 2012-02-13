require 'spec_helper'

class JSON_API < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::JSONP
  use Goliath::Rack::Render, 'json'

  def response(env)
    [200, {'CONTENT_TYPE' => 'application/json'}, "OK"]
  end
end

describe 'JSONP' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'sets the content type' do
    with_api(JSON_API) do
      get_request({:query => {:callback => 'test'}}, err) do |c|
        c.response_header['CONTENT_TYPE'].should =~ %r{^application/javascript}
      end
    end
  end

  it 'wraps response with callback' do
    with_api(JSON_API) do
      get_request({:query => {:callback => 'test'}}, err) do |c|
        c.response.should =~ /^test\(.*\)$/
      end
    end
  end
end