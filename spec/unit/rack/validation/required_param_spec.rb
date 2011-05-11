require 'spec_helper'
require 'goliath/rack/validation/required_param'

describe Goliath::Rack::Validation::RequiredParam do
  it 'accepts an app' do
    lambda { Goliath::Rack::Validation::RequiredParam.new('my app') }.should_not raise_error
  end

  it 'accepts options on create' do
    opts = { :type => 1, :key => 2, :message => 'is required' }
    lambda { Goliath::Rack::Validation::RequiredParam.new('my app', opts) }.should_not raise_error
  end

  it 'defaults type, key and message' do
    @rp = Goliath::Rack::Validation::RequiredParam.new('app')
    @rp.key.should_not be_nil
    @rp.key.should_not =~ /^\s*$/

    @rp.type.should_not be_nil
    @rp.type.should_not =~ /^\s*$/

    @rp.message.should == 'identifier missing'
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = {'params' => {}}
      @rp = Goliath::Rack::Validation::RequiredParam.new(@app, {:type => 'Monkey', :key => 'mk', :message => 'is required'})
    end

    it 'stores type and key options' do
      @rp.type.should == 'Monkey'
      @rp.key.should == 'mk'
    end

    it 'calls validation_error with a custom message' do
      @rp.should_receive(:validation_error).with(anything, 'Monkey is required')
      @rp.call(@env)
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      @app.should_receive(:call).and_return([201, app_headers, app_body])

      @env['params']['mk'] = 'monkey'

      status, headers, body = @rp.call(@env)
      status.should == 201
      headers.should == app_headers
      body.should == app_body
    end

    describe 'key_valid?' do
      it 'raises exception if the key is not provided' do
        @rp.key_valid?(@env['params']).should be_false
      end

      it 'raises exception if the key is blank' do
        @env['params']['mk'] = ''
        @rp.key_valid?(@env['params']).should be_false
      end

      it 'raises exception if the key is nil' do
        @env['params']['mk'] = nil
        @rp.key_valid?(@env['params']).should be_false
      end

      it 'handles an empty array' do
        @env['params']['mk'] = []
        @rp.key_valid?(@env['params']).should be_false
      end

      it 'handles an array of nils' do
        @env['params']['mk'] = [nil, nil, nil]
        @rp.key_valid?(@env['params']).should be_false
      end

      it 'handles an array of blanks' do
        @env['params']['mk'] = ['', '', '']
        @rp.key_valid?(@env['params']).should be_false
      end

      it "doesn't raise if the key provided" do
        @env['params']['mk'] = 'my value'
        @rp.key_valid?(@env['params']).should be_true
      end

      it "doesn't raise if the array contains valid data" do
        @env['params']['mk'] = [1, 2, 3, 4]
        @rp.key_valid?(@env['params']).should be_true
      end
    end
  end
end
