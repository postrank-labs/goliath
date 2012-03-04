require 'spec_helper'

class StandardServerHeader < Goliath::API
  def response(env)
    [201, {'StandardServer' => 'y'}, []]
  end
end

class UnsetServerHeader < Goliath::API
  def response(env)
    [201, {'Server' => nil, 'UnsetServer' => 'y'}, []]
  end
end

class CustomServerHeader < Goliath::API
  def response(env)
    [201, {'Server' => 'Custom', 'CustomServer' => 'y'}, []]
  end
end

class ForbidOtherNilHeaders < Goliath::API
  def response(env)
    [201, {'ForbidOtherNilHeadersServer' => 'y', 'Other' =>nil}, []]
  end
end

describe 'Standard server header API' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'Serves the standard server header' do
    with_api(StandardServerHeader) do
      get_request({}, err) do |c|
        c.response_header['Server'].should == 'Goliath'
        c.response_header['StandardServer'].should == 'y'
        c.response_header['UnsetServer'].should_not == 'y'
        c.response_header['CustomServer'].should_not == 'y'
        c.response_header['ForbidOtherNilHeadersServer'].should_not == 'y'
      end
    end
  end
end

describe 'Empty server header API' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'Serves the empty server header' do
    with_api(UnsetServerHeader) do
      get_request({}, err) do |c|
        c.response_header['Server'].should == nil
        c.response_header['StandardServer'].should_not == 'y'
        c.response_header['UnsetServer'].should == 'y'
        c.response_header['CustomServer'].should_not == 'y'
        c.response_header['ForbidOtherNilHeadersServer'].should_not == 'y'
      end
    end
  end
end

describe 'Custom server header API' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'Serves the custom server header' do
    with_api(CustomServerHeader) do
      get_request({}, err) do |c|
        c.response_header['Server'].should == 'Custom'
        c.response_header['StandardServer'].should_not == 'y'
        c.response_header['UnsetServer'].should_not == 'y'
        c.response_header['CustomServer'].should == 'y'
        c.response_header['ForbidOtherNilHeadersServer'].should_not == 'y'
      end
    end
  end
end

describe 'NilOtherForbid Server header API' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'Prevents non-Server nil values server header' do
    with_api(ForbidOtherNilHeaders) do
      get_request({}, err) do |c|
        (c.response_header['Other'] == nil and c.response_header.has_key? 'Other').should_not == true
        c.response_header['StandardServer'].should_not == 'y'
        c.response_header['UnsetServer'].should_not == 'y'
        c.response_header['CustomServer'].should_not == 'y'
        c.response_header['ForbidOtherNilHeadersServer'].should == 'y'
      end
    end
  end
end
