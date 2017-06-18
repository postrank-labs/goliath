require 'spec_helper'
require 'goliath/rack/validation/boolean_value'

describe Goliath::Rack::Validation::BooleanValue do
  before(:each) do
    @app = double('app').as_null_object
    @env = {'params' => {}}
  end

  describe 'with middleware' do
    before(:each) do
      @bv = Goliath::Rack::Validation::BooleanValue.new(@app, {:key => 'id', :default => true})
    end

    it 'uses the default if the key is not present' do
      @bv.call(@env)
      expect(@env['params']['id']).to eq(true)
    end

    it 'uses the default if the key is nil' do
      @env['params']['id'] = nil
      @bv.call(@env)
      expect(@env['params']['id']).to eq(true)
    end

    it 'uses the default if the key is blank' do
      @env['params']['id'] = ""
      @bv.call(@env)
      expect(@env['params']['id']).to eq(true)
    end

    it 'a random value is false' do
      @env['params']['id'] = 'blarg'
      @bv.call(@env)
      expect(@env['params']['id']).to eq(false)
    end

    %w(t true TRUE T 1).each do |type|
      it "considers #{type} true" do
        @env['params']['id'] = type
        @bv.call(@env)
        expect(@env['params']['id']).to eq(true)
      end
    end

    %w(f false FALSE F 0).each do |type|
      it "considers #{type} false" do
        @env['params']['id'] = type
        @bv.call(@env)
        expect(@env['params']['id']).to eq(false)
      end
    end
  end
end
