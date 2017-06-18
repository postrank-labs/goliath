require 'spec_helper'
require 'goliath/rack/validation/numeric_range'

describe Goliath::Rack::Validation::NumericRange do
  before(:each) do
    @app = double('app').as_null_object
    @env = {'params' => {}}
  end

  it 'accepts options on create' do
    opts = { :min => 1, :key => 2 }
    expect { Goliath::Rack::Validation::NumericRange.new('my app', opts) }.not_to raise_error
  end

  describe 'with middleware' do
    before(:each) do
      @nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :min => -5, :max => 20, :default => 15})
    end

    it 'uses the default if value is less then min' do
      @env['params']['id'] = -10
      @nr.call(@env)
      expect(@env['params']['id']).to eq(15)
    end

    it 'uses the default if value is greater then max' do
      @env['params']['id'] = 25
      @nr.call(@env)
      expect(@env['params']['id']).to eq(15)
    end

    it 'uses the first value, if the value is an array' do
      @env['params']['id'] = [10, 11, 12]
      @nr.call(@env)
      expect(@env['params']['id']).to eq(10)
    end

    it 'uses the default if value is not present' do
      @nr.call(@env)
      expect(@env['params']['id']).to eq(15)
    end

    it 'uses the default if value is nil' do
      @env['params']['id'] = nil
      @nr.call(@env)
      expect(@env['params']['id']).to eq(15)
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      expect(@app).to receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @nr.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq(app_headers)
      expect(body).to eq(app_body)
    end
  end

  it 'converts to a float with :as => Float' do
    nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :min => 1.1, :as => Float})
    @env['params']['id'] = 1.5
    nr.call(@env)
    expect(@env['params']['id']).to eq(1.5)
  end

  it 'raises error if key is not set' do
    expect { Goliath::Rack::Validation::NumericRange.new('app', {:min => 5}) }.to raise_error('NumericRange key required')
  end

  it 'raises error if neither min nor max set' do
    expect { Goliath::Rack::Validation::NumericRange.new('app', {:key => 5}) }.to raise_error('NumericRange requires :min or :max')
  end

  it 'uses min if default not set' do
    nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :min => 5, :max => 10})
    @env['params']['id'] = 15
    nr.call(@env)
    expect(@env['params']['id']).to eq(5)
  end

  it 'uses max if default and min not set' do
    nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :max => 10})
    @env['params']['id'] = 15
    nr.call(@env)
    expect(@env['params']['id']).to eq(10)
  end

  it "doesn't require min" do
    nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :max => 10})
    @env['params']['id'] = 8
    nr.call(@env)
    expect(@env['params']['id']).to eq(8)
  end

  it "doesn't require max" do
    nr = Goliath::Rack::Validation::NumericRange.new(@app, {:key => 'id', :min => 1})
    @env['params']['id'] = 15
    nr.call(@env)
    expect(@env['params']['id']).to eq(15)
  end
end
