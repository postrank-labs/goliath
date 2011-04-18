require 'spec_helper'
require 'json'
require File.join(File.dirname(__FILE__), '../../', 'examples/valid')

describe Valid do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns OK with param' do
    with_api(Valid) do
      get_request({:query => {:test => 'test'}}, err) do |c|
        c.response.should == 'OK'
      end
    end
  end

  it 'returns error without param' do
    with_api(Valid) do
      get_request({}, err) do |c|
        c.response.should == '[:error, "Test identifier missing"]'
      end
    end
  end
end

class ValidationErrorInEndpointButNoHandler < Goliath::API
  use Goliath::Rack::Params
  def response(env)
    raise Goliath::Validation::Error.new(420, 'YOU MUST CHILL')
  end
end

class ValidationErrorInEndpoint < ValidationErrorInEndpointButNoHandler
  use Goliath::Rack::ValidationError
end

describe ValidationErrorInEndpoint do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'handles Goliath::Rack::ValidationError handle the error when included' do
    with_api(ValidationErrorInEndpoint) do
      get_request({}, err) do |c|
        c.response.should == '[:error, "YOU MUST CHILL"]'
        c.response_header.status.should == 420
      end
    end
  end
end

describe ValidationErrorInEndpointButNoHandler do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'treats Goliath::Validation::Error same as any exception' do
    with_api(ValidationErrorInEndpointButNoHandler) do
      get_request({}, err) do |c|
        c.response.should == '[:error, "YOU MUST CHILL"]'
        c.response_header.status.should == 400
      end
    end
  end
end
