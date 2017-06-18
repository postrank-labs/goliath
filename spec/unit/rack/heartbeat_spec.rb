require 'spec_helper'
require 'goliath/rack/heartbeat'
require 'goliath/env'

describe Goliath::Rack::Heartbeat do
  it 'accepts an app' do
    expect { Goliath::Rack::Heartbeat.new('my app') }.not_to raise_error
  end

  describe 'with the middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @env = Goliath::Env.new
      @env['status'] = double('status').as_null_object
      @hb = Goliath::Rack::Heartbeat.new(@app)
    end

    it 'allows /status as a path prefix' do
      expect(@app).to receive(:call)
      @env['PATH_INFO'] = '/status_endpoint'
      @hb.call(@env)
    end

    it "doesn't call the app when request /status" do
      expect(@app).not_to receive(:call)
      @env['PATH_INFO'] = '/status'
      @hb.call(@env)
    end

    it 'returns the status, headers and body from the app on non-/status' do
      @env['PATH_INFO'] = '/v1'
      expect(@app).to receive(:call).and_return([200, {'a' => 'b'}, {'c' => 'd'}])
      status, headers, body = @hb.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq({'a' => 'b'})
      expect(body).to eq({'c' => 'd'})
    end

    it 'returns the correct status, headers and body on /status' do
      @env['PATH_INFO'] = '/status'
      status, headers, body = @hb.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq({})
      expect(body).to eq('OK')
    end

    it 'allows path and response to be set using options' do
      @hb = Goliath::Rack::Heartbeat.new(@app, :path => '/isup', :response => [204, {}, nil])
      @env['PATH_INFO'] = '/isup'
      status, headers, body = @hb.call(@env)
      expect(status).to eq(204)
      expect(headers).to eq({})
      expect(body).to eq(nil)
    end

    it 'does not log the request by default' do
      @env['PATH_INFO'] = '/status'
      @hb.call(@env)
      expect(@env[Goliath::Constants::RACK_LOGGER]).to eq(Log4r::Logger.root)
    end

    it 'logs the request only if asked' do
      @env['PATH_INFO'] = '/status'
      @hb = Goliath::Rack::Heartbeat.new(@app, :log => true)
      @hb.call(@env)
      expect(@env[Goliath::Constants::RACK_LOGGER]).not_to eq(Log4r::Logger.root)
    end
  end
end

