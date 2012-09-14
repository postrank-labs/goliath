require 'spec_helper'
require 'goliath/rack/path_params'

describe Goliath::Rack::PathParams do
  it 'accepts an app and a url pattern' do
    lambda { Goliath::Rack::PathParams.new('my app', 'url') }.should_not raise_error
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = { 'REQUEST_PATH' => '/records/the_fall/hex_enduction_hour' }
      @path_params = Goliath::Rack::PathParams.new(@app, '/records/:artist/:title')
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      @app.should_receive(:call).and_return([201, app_headers, app_body])

      status, headers, body = @path_params.call(@env)
      status.should == 201
      headers.should == app_headers
      body.should == app_body
    end

    context 'a request that does not end in a slash' do
      before do
        @env = { 'REQUEST_PATH' => '/records/sparks/angst_in_my_pants' }
      end

      it 'parses the params from the path' do
        @path_params.call(@env)
        @env['params']['artist'].should == 'sparks'
        @env['params']['title'].should == 'angst_in_my_pants'
      end
    end

    context 'a request that ends in a slash' do
      before do
        @env = { 'REQUEST_PATH' => '/records/kraftwerk/trans_europe_express/?remix' }
      end

      it 'parses the params from the path' do
        @path_params.call(@env)
        @env['params']['artist'].should == 'kraftwerk'
        @env['params']['title'].should == 'trans_europe_express'
      end
    end

    context 'a request that ends with query params' do
      before do
        @env = { 'REQUEST_PATH' => '/records/can/tago_mago?genre=krautrock' }
      end

      it 'parses the params from the path' do
        @path_params.call(@env)
        @env['params']['artist'].should == 'can'
        @env['params']['title'].should == 'tago_mago'
      end
    end

  end
end
