require 'spec_helper'
require 'goliath/rack/validation/default_params'

describe Goliath::Rack::Validation::DefaultParams do
  it 'accepts an app' do
    opts = {:defaults => ['title'], :key => 'fields'}
    expect { Goliath::Rack::Validation::DefaultParams.new('my app', opts) }.not_to raise_error
  end

  it 'requires defaults to be set' do
    expect { Goliath::Rack::Validation::DefaultParams.new('my app', {:key => 'test'}) }.to raise_error('Must provide defaults to DefaultParams')
  end

  it 'requires key to be set' do
    expect { Goliath::Rack::Validation::DefaultParams.new('my app', {:defaults => 'test'}) }.to raise_error('must provide key to DefaultParams')
  end

  describe 'with middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @env = {'params' => {}}
      @rf = Goliath::Rack::Validation::DefaultParams.new(@app, {:key => 'fl', :defaults => ['title', 'link']})
    end

    it 'passes through provided key if set' do
      @env['params']['fl'] = ['pubdate', 'content']
      @rf.call(@env)
      expect(@env['params']['fl']).to eq(['pubdate', 'content'])
    end

    it 'sets defaults if no key set' do
      @rf.call(@env)
      expect(@env['params']['fl']).to eq(['title', 'link'])
    end

    it 'sets defaults if no key set' do
      @env['params']['fl'] = nil
      @rf.call(@env)
      expect(@env['params']['fl']).to eq(['title', 'link'])
    end

    it 'sets defaults if no key is empty' do
      @env['params']['fl'] = []
      @rf.call(@env)
      expect(@env['params']['fl']).to eq(['title', 'link'])
    end

    it 'handles a single item' do
      @env['params']['fl'] = 'title'
      @rf.call(@env)
      expect(@env['params']['fl']).to eq('title')
    end

    it 'handles a blank string' do
      @env['params']['fl'] = ''
      @rf.call(@env)
      expect(@env['params']['fl']).to eq(['title', 'link'])
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'asdf'}
      app_body = {'a' => 'b'}
      expect(@app).to receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @rf.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq(app_headers)
      expect(body).to eq(app_body)
    end
  end
end
