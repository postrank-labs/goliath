require 'spec_helper'
require 'goliath/rack/validation/required_value'

describe Goliath::Rack::Validation::RequiredValue do
  it 'accepts an app' do
    lambda { Goliath::Rack::Validation::RequiredValue.new('my app') }.should_not raise_error
  end

  it 'accepts options on create' do
    opts = { :key => 2, :values => ["foo", "bar"] }
    lambda { Goliath::Rack::Validation::RequiredValue.new('my app', opts) }.should_not raise_error
  end


  it 'turns a single option into an array' do
    rv = Goliath::Rack::Validation::RequiredValue.new('my app', :key => 2, :values => "foo")
    rv.values.should == ['foo']
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = {'params' => {}}
      @rv = Goliath::Rack::Validation::RequiredValue.new(@app, {:values => ['Monkey', 'frog'], :key => 'mk'})
    end

    it 'stores type and key options' do
      @rv.values.should == ['Monkey', 'frog']
      @rv.key.should == 'mk'
    end

    it 'returns the app status, headers and body' do
      app_headers = {'Content-Type' => 'app'}
      app_body = {'b' => 'c'}
      @app.should_receive(:call).and_return([201, app_headers, app_body])

      @env['params']['mk'] = 'Monkey'

      status, headers, body = @rv.call(@env)
      status.should == 201
      headers.should == app_headers
      body.should == app_body
    end

    context '#value_valid!' do
      it 'raises exception if the key is not provided' do
        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'raises exception if the key is blank' do
        @env['params']['mk'] = ''

        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'raises exception if the key is nil' do
        @env['params']['mk'] = nil

        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'raises exception if the key is does not match' do
        @env['params']['mk'] = "blarg"

        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'handles an empty array' do
        @env['params']['mk'] = []
        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'handles an array of nils' do
        @env['params']['mk'] = [nil, nil, nil]
        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it 'handles an array of blanks' do
        @env['params']['mk'] = ['', '', '']
        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end

      it "doesn't raise if the key is value" do
        @env['params']['mk'] = 'Monkey'
        lambda { @rv.value_valid!(@env['params']) }.should_not raise_error(Goliath::Validation::Error)
      end

      it "doesn't raise if the array contains valid data" do
        @env['params']['mk'] = ['Monkey', 'frog']
        lambda{ @rv.value_valid!(@env['params']) }.should_not raise_error
      end

      it 'raises if any of the array elements do not match' do
        @env['params']['mk'] = ["Monkey", "frog", "bat"]
        lambda { @rv.value_valid!(@env['params']) }.should raise_error(Goliath::Validation::Error)
      end
    end
  end
end
