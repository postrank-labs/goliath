require 'spec_helper'
require 'goliath/rack/heartbeat'
require 'goliath/env'

describe Goliath::Rack::Heartbeat do
  it 'accepts an app' do
    lambda { Goliath::Rack::Heartbeat.new('my app') }.should_not raise_error
  end

  describe 'with the middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = Goliath::Env.new
      @env['status'] = mock('status').as_null_object
      @hb = Goliath::Rack::Heartbeat.new(@app)
    end

    it 'allows /status as a path prefix' do
      @app.should_receive(:call)
      @env['PATH_INFO'] = '/status_endpoint'
      @hb.call(@env)
    end

    it "doesn't call the app when request /status" do
      @app.should_not_receive(:call)
      @env['PATH_INFO'] = '/status'
      @hb.call(@env)
    end

    it 'returns the status, headers and body from the app on non-/status' do
      @env['PATH_INFO'] = '/v1'
      @app.should_receive(:call).and_return([200, {'a' => 'b'}, {'c' => 'd'}])
      status, headers, body = @hb.call(@env)
      status.should == 200
      headers.should == {'a' => 'b'}
      body.should == {'c' => 'd'}
    end

    it 'returns the correct status, headers and body on /status' do
      @env['PATH_INFO'] = '/status'
      status, headers, body = @hb.call(@env)
      status.should == 200
      headers.should == {}
      body.should == 'OK'
    end

    it 'allows path and response to be set using options' do
      @hb = Goliath::Rack::Heartbeat.new(@app, :path => '/isup', :response => [204, {}, nil])
      @env['PATH_INFO'] = '/isup'
      status, headers, body = @hb.call(@env)
      status.should == 204
      headers.should == {}
      body.should == nil
    end

    it 'does not log the request by default' do
      @env['PATH_INFO'] = '/status'
      @hb.call(@env)
      @env[Goliath::Constants::RACK_LOGGER].should == Log4r::Logger.root
    end

    it 'logs the request only if asked' do
      @env['PATH_INFO'] = '/status'
      @hb = Goliath::Rack::Heartbeat.new(@app, :log => true)
      @hb.call(@env)
      @env[Goliath::Constants::RACK_LOGGER].should_not == Log4r::Logger.root
    end
  end
end

