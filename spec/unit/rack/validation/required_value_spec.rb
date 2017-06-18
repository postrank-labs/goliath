require 'spec_helper'
require 'goliath/rack/validation/required_value'

describe Goliath::Rack::Validation::RequiredValue do
  it 'accepts an app' do
    expect { Goliath::Rack::Validation::RequiredValue.new('my app') }.not_to raise_error
  end

  it 'accepts options on create' do
    opts = { :key => 2, :values => ["foo", "bar"] }
    expect { Goliath::Rack::Validation::RequiredValue.new('my app', opts) }.not_to raise_error
  end


  it 'turns a single option into an array' do
    rv = Goliath::Rack::Validation::RequiredValue.new('my app', :key => 2, :values => "foo")
    expect(rv.values).to eq(['foo'])
  end

  describe 'with middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @env = {'params' => {}}
      @rv = Goliath::Rack::Validation::RequiredValue.new(@app, {:values => ['Monkey', 'frog'], :key => 'mk'})
    end

    it 'stores type and key options' do
      expect(@rv.values).to eq(['Monkey', 'frog'])
      expect(@rv.key).to eq('mk')
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      expect(@app).to receive(:call).and_return([201, app_headers, app_body])

      @env['params']['mk'] = 'Monkey'

      status, headers, body = @rv.call(@env)
      expect(status).to eq(201)
      expect(headers).to eq(app_headers)
      expect(body).to eq(app_body)
    end

    context '#value_valid!' do
      it 'raises exception if the key is not provided' do
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'raises exception if the key is blank' do
        @env['params']['mk'] = ''
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'raises exception if the key is nil' do
        @env['params']['mk'] = nil
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'raises exception if the key is does not match' do
        @env['params']['mk'] = "blarg"
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'handles an empty array' do
        @env['params']['mk'] = []
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'handles an array of nils' do
        @env['params']['mk'] = [nil, nil, nil]
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it 'handles an array of blanks' do
        @env['params']['mk'] = ['', '', '']
        expect(@rv.value_valid?(@env['params'])).to be false
      end

      it "doesn't raise if the key is value" do
        @env['params']['mk'] = 'Monkey'
        expect(@rv.value_valid?(@env['params'])).to be true
      end

      it "doesn't raise if the array contains valid data" do
        @env['params']['mk'] = ['Monkey', 'frog']
        expect(@rv.value_valid?(@env['params'])).to be true
      end

      it 'raises if any of the array elements do not match' do
        @env['params']['mk'] = ["Monkey", "frog", "bat"]
        expect(@rv.value_valid?(@env['params'])).to be false
      end
    end
  end
end
