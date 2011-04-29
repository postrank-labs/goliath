# encoding: utf-8
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/rack_routes')

describe RackRoutes do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'routes to the correct API' do
    with_api(RackRoutes) do
      get_request({:path => '/bonjour'}, err) do |c|
        c.response_header.status.should == 200
        c.response.should == 'bonjour!'
      end
    end
  end

  it 'routes to the default' do
    with_api(RackRoutes) do
      get_request({:path => '/donkey'}, err) do |c|
        c.response_header.status.should == 404
        c.response.should == 'Try /version /hello_world, /bonjour, or /hola'
      end
    end
  end

  it 'uses API middleware' do
    with_api(RackRoutes) do
      post_request({:path => '/hola'}, err) do |c|
        # the /hola route only supports GET requests
        c.response_header.status.should == 400
        c.response.should == '[:error, "Invalid request method"]'
      end
    end
  end

  it 'uses API middleware' do
    with_api(RackRoutes) do
      post_request({:path => '/aloha'}, err) do |c|
        # the /hola route only supports GET requests
        c.response_header.status.should == 400
        c.response.should == '[:error, "Invalid request method"]'
      end
    end
  end
end