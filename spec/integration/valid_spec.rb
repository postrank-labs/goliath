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

class ValidationErrorInEndpoint < Goliath::API
  def response(env)
    raise Goliath::Validation::Error.new(420, 'You Must Chill')
  end
end

describe ValidationErrorInEndpoint do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'handles Goliath::Validation::Error correctly' do
    with_api(ValidationErrorInEndpoint) do
      get_request({}, err) do |c|
        c.response.should == '[:error, "You Must Chill"]'
        c.response_header.status.should == 420
      end
    end
  end
end

