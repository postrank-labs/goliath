require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/echo')
require 'multipart_body'
require 'yajl' if RUBY_PLATFORM != 'java'

describe Echo do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns the echo param' do
    with_api(Echo) do
      get_request({:query => {:echo => 'test'}}, err) do |c|
        b = MultiJson.load(c.response)
        b['response'].should == 'test'
      end
    end
  end

  it 'returns error without echo' do
    with_api(Echo) do
      get_request({}, err) do |c|
        b = MultiJson.load(c.response)
        b['error'].should_not be_nil
        b['error'].should == 'echo identifier missing'
      end
    end
  end

  it 'echos POST data' do
    with_api(Echo) do
      post_request({:body => {'echo' => 'test'}}, err) do |c|
        b = MultiJson.load(c.response)
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
        b = MultiJson.load(c.response)
        b['response'].should == 'test'
      end
    end
  end

  it 'echos application/json POST body data' do
    with_api(Echo) do
      body = MultiJson.dump({'echo' => 'My Echo'})
      head = {'content-type' => 'application/json'}

      post_request({:body => body.to_s,
                    :head => head}, err) do |c|
        b = MultiJson.load(c.response)
        b['response'].should == 'My Echo'
      end
    end
  end

  it 'echos PATCH data' do
    with_api(Echo) do
      patch_request({:body => {'echo' => 'test'}}, err) do |c|
        b = MultiJson.load(c.response)
        b['response'].should == 'test'
      end
    end
  end
end
