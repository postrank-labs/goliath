# encoding: utf-8
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/rack_routes')

describe RackRoutes do
  let(:err) { Proc.new { fail "API request failed" } }

  context "when using maps" do

    it "ignores #response" do
      expect {
        with_api(RackRoutes) do
          get_request({:path => '/'}, err) {}
        end
      }.to_not raise_error
    end

    it 'fallback not found to /' do
      with_api(RackRoutes) do
        get_request({:path => '/donkey'}, err) do |cb|
          cb.response_header.status.should == 404
          cb.response.should == 'Try /version /hello_world, /bonjour, or /hola'
        end
      end
    end

    it 'routes to the correct API' do
      with_api(RackRoutes) do
        get_request({:path => '/bonjour'}, err) do |c|
          c.response_header.status.should == 200
          c.response.should == 'bonjour!'
        end
      end
    end

    it 'routes to the correct API using regex filters' do
      with_api(RackRoutes) do
        get_request({:path => '/123123'}, err) do |c|
          c.response_header.status.should == 200
          c.response.should == 'number 123123!'
        end
      end
    end

    context 'sinatra style route definition' do
      it 'should honor the request method' do
        with_api(RackRoutes) do
          post_request({:path => '/hello_world'}, err) do |c|
            c.response_header.status.should == 200
            c.response.should == 'hello post world!'
          end
        end
      end
      it 'should reject other request methods' do
        with_api(RackRoutes) do
          put_request({:path => '/hello_world'}, err) do |c|
            c.response_header.status.should == 405
            c.response_header['ALLOW'].split(/, /).should == %w(GET HEAD POST)
          end
        end
      end
    end

    context 'routes defined with get' do
      it 'should allow get' do
        with_api(RackRoutes) do
          get_request({:path => '/hello_world'}, err) do |c|
            c.response_header.status.should == 200
            c.response.should == 'hello world!'
          end
        end
      end
      it 'should allow head' do
        with_api(RackRoutes) do
          head_request({:path => '/hello_world'}, err) do |c|
            c.response_header.status.should == 200
            c.response.should == 'hello world!'
          end
        end
      end
    end

    context "defined in blocks" do
      it 'uses middleware defined in the block' do
        with_api(RackRoutes) do
          post_request({:path => '/hola'}, err) do |c|
            # the /hola route only supports GET requests
            c.response_header.status.should == 405
            c.response.should == '[:error, "Invalid request method"]'
            c.response_header['ALLOW'].should == 'GET'
          end
        end
      end

      it "doesn't use middleware defined in the API" do
        with_api(RackRoutes) do
          get_request({:path => '/hola'}, err) do |cb|
            # it doesn't raise required param error
            cb.response_header.status.should == 200
            cb.response.should == "hola!"
          end
        end
      end
    end

    context "defined in classes" do
      it 'uses API middleware' do
        with_api(RackRoutes) do
          post_request({:path => '/aloha'}, err) do |c|
            # the /hola route only supports GET requests
            c.response_header.status.should == 405
            c.response.should == '[:error, "Invalid request method"]'
            c.response_header['ALLOW'].should == 'GET'
          end
        end
      end
    end

  end
end
