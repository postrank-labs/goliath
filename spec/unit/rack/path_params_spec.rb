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

    context 'a request that matches the url pattern' do
      before do
        @env = { 'REQUEST_PATH' => '/records/sparks/angst_in_my_pants' }
      end

      it 'parses the params from the path' do
        @path_params.call(@env)
        @env['params']['artist'].should == 'sparks'
        @env['params']['title'].should == 'angst_in_my_pants'
      end
    end

    context 'a request that does not match the url pattern' do
      before do
        @env = { 'REQUEST_PATH' => '/animals/cat/noah' }
      end

      it 'raises a BadRequestError' do
        expect{ @path_params.retrieve_params(@env) }.to raise_error(Goliath::Validation::BadRequestError)
      end
    end

  end
end
