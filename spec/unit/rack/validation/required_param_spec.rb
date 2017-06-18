require 'spec_helper'
require 'goliath/rack/validation/required_param'

describe Goliath::Rack::Validation::RequiredParam do
  it 'accepts an app' do
    expect { Goliath::Rack::Validation::RequiredParam.new('my app') }.not_to raise_error
  end

  it 'accepts options on create' do
    opts = { :type => 1, :key => 2, :message => 'is required' }
    expect { Goliath::Rack::Validation::RequiredParam.new('my app', opts) }.not_to raise_error
  end

  it 'defaults type, key and message' do
    @rp = Goliath::Rack::Validation::RequiredParam.new('app')
    expect(@rp.key).not_to be_nil
    expect(@rp.key).not_to match(/^\s*$/)

    expect(@rp.type).not_to be_nil
    expect(@rp.type).not_to match(/^\s*$/)

    expect(@rp.message).to eq('identifier missing')
  end

  describe 'with middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @env = {'params' => {}}
      @rp = Goliath::Rack::Validation::RequiredParam.new(@app, {:type => 'Monkey', :key => 'mk', :message => 'is required'})
    end

    it 'stores type and key options' do
      expect(@rp.type).to eq('Monkey')
      expect(@rp.key).to eq('mk')
    end

    it 'calls validation_error with a custom message' do
      expect(@rp).to receive(:validation_error).with(anything, 'Monkey is required')
      @rp.call(@env)
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      expect(@app).to receive(:call).and_return([201, app_headers, app_body])

      @env['params']['mk'] = 'monkey'

      status, headers, body = @rp.call(@env)
      expect(status).to eq(201)
      expect(headers).to eq(app_headers)
      expect(body).to eq(app_body)
    end

    describe 'key_valid?' do
      it 'raises exception if the key is not provided' do
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it 'raises exception if the key is blank' do
        @env['params']['mk'] = ''
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it 'raises exception if the key is nil' do
        @env['params']['mk'] = nil
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it 'handles an empty array' do
        @env['params']['mk'] = []
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it 'handles an array of nils' do
        @env['params']['mk'] = [nil, nil, nil]
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it 'handles an array of blanks' do
        @env['params']['mk'] = ['', '', '']
        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it "doesn't raise if the key provided" do
        @env['params']['mk'] = 'my value'
        expect(@rp.key_valid?(@env['params'])).to be true
      end

      it "doesn't raise if the array contains valid data" do
        @env['params']['mk'] = [1, 2, 3, 4]
        expect(@rp.key_valid?(@env['params'])).to be true
      end

      it "doesn't raise if the key provided is multiline and has blanks" do
        @env['params']['mk'] = "my\n  \nvalue"
        expect(@rp.key_valid?(@env['params'])).to be true
      end

      it "doesn't raise if the key provided is an array and contains multiline with blanks" do
        @env['params']['mk'] = ["my\n  \nvalue", "my\n  \nother\n  \nvalue"]
        expect(@rp.key_valid?(@env['params'])).to be true
      end
    end
  end

  describe 'Nested keys tests' do
    before do
      @app = double('app').as_null_object
      @env = {'params' => {}}
      @rp = Goliath::Rack::Validation::RequiredParam.new(@app,
          :type => 'Monkey',
          :key => ['data', 'credentials', 'login'],
          :message => 'is required'
        )
    end

    it "return false if key's missing" do
      @env['params'] = {'data' => {
          'credentials' => {
              'login2' => "user",
              'pass' => "password"}
            }
        }

      expect(@rp.key_valid?(@env['params'])).to be false
    end

    it "return true if key is present" do
      @env['params'] = {'data' => {
          'credentials' => {
              'login' => "user",
              'pass' => "password"}
            }
        }

      expect(@rp.key_valid?(@env['params'])).to be true
    end
  end

  describe 'Nested keys tests (with string)' do
    before do
      @app = double('app').as_null_object
      @env = {'params' => {}}
      @rp = Goliath::Rack::Validation::RequiredParam.new(@app,
          :type => 'Monkey',
          :key => 'data.credentials.login',
          :message => 'is required'
        )
    end

    it "return false if key's missing" do
      @env['params'] = {'data' => {
          'credentials' => {
              'login2' => "user",
              'pass' => "password"}
            }
        }

      expect(@rp.key_valid?(@env['params'])).to be false
    end

    it "return true if key is present" do
      @env['params'] = {'data' => {
          'credentials' => {
              'login' => "user",
              'pass' => "password"}
            }
        }

      expect(@rp.key_valid?(@env['params'])).to be true
    end
  end


end
