require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/echo')

describe Echo do
  include Goliath::TestHelper

  it 'returns the echo param' do
    with_api(Echo) do
      get_request(:query => {:echo => 'test'}) do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'
      end
    end
  end

  it 'returns error without echo' do
    with_api(Echo) do
      get_request do |c|
        b = Yajl::Parser.parse(c.response)
        b['error'].should_not be_nil
        b['error'].should == 'Echo identifier missing'
      end
    end
  end
end
