require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/echo')
require 'multipart_body'

describe Echo do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns the echo param' do
    with_api(Echo) do
      get_request({:query => {:echo => 'test'}}, err) do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'
      end
    end
  end

  it 'returns error without echo' do
    with_api(Echo) do
      get_request({}, err) do |c|
        b = Yajl::Parser.parse(c.response)
        b['error'].should_not be_nil
        b['error'].should == 'Echo identifier missing'
      end
    end
  end

  it 'echos POST data' do
    with_api(Echo) do
      post_request({:body => {'echo' => 'test'}}, err) do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'
      end
    end
  end

  it 'echos POST data that is multipart encoded' do
    with_api(Echo) do
      body = MultipartBody.new(:echo => 'test')
      head = {'content-type' => "multipart/form-data; boundary=#{body.boundary}"}

      post_request({:body => body.to_s,
                    :head => head}, err) do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'
      end
    end
  end

end
