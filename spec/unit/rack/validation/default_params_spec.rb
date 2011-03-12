require 'spec_helper'
require 'goliath/rack/validation/default_params'

describe Goliath::Rack::Validation::DefaultParams do
  it 'accepts an app' do
    opts = {:defaults => ['title'], :key => 'fields'}
    lambda { Goliath::Rack::Validation::DefaultParams.new('my app', opts) }.should_not raise_error
  end

  it 'requires defaults to be set' do
    lambda { Goliath::Rack::Validation::DefaultParams.new('my app', {:key => 'test'}) }.should raise_error
  end

  it 'requires key to be set' do
    lambda { Goliath::Rack::Validation::DefaultParams.new('my app', {:defaults => 'test'}) }.should raise_error
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = {'params' => {}}
      @rf = Goliath::Rack::Validation::DefaultParams.new(@app, {:key => 'fl', :defaults => ['title', 'link']})
    end

    it 'passes through provided key if set' do
      @env['params']['fl'] = ['pubdate', 'content']
      @rf.call(@env)
      @env['params']['fl'].should == ['pubdate', 'content']
    end

    it 'sets defaults if no key set' do
      @rf.call(@env)
      @env['params']['fl'].should == ['title', 'link']
    end

    it 'sets defaults if no key set' do
      @env['params']['fl'] = nil
      @rf.call(@env)
      @env['params']['fl'].should == ['title', 'link']
    end

    it 'sets defaults if no key is empty' do
      @env['params']['fl'] = []
      @rf.call(@env)
      @env['params']['fl'].should == ['title', 'link']
    end

    it 'handles a single item' do
      @env['params']['fl'] = 'title'
      @rf.call(@env)
      @env['params']['fl'].should == 'title'
    end

    it 'handles a blank string' do
      @env['params']['fl'] = ''
      @rf.call(@env)
      @env['params']['fl'].should == ['title', 'link']
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'asdf'}
      app_body = {'a' => 'b'}
      @app.should_receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @rf.call(@env)
      status.should == 200
      headers.should == app_headers
      body.should == app_body
    end
  end
end
