require 'spec_helper'
require 'goliath/env'

describe Goliath::Env do
  before(:each) do
    @env = Goliath::Env.new
  end

  it 'responds to []=' do
    lambda { @env['test'] = 'blah' }.should_not raise_error
  end

  it 'responds to []' do
    @env['test'] = 'blah'
    lambda { @env['test'].should == 'blah' }.should_not raise_error
  end

  context '#method_missing' do
    it 'allows access to items as methods' do
      @env['db'] = 'test'
      @env.db.should == 'test'
    end

    it 'allows access to config items as methods' do
      @env['config'] = {}
      @env['config']['db'] = 'test'
      @env.db.should == 'test'
    end
  end

  context '#respond_to?' do
    it 'returns true for items in the hash' do
      @env['test'] = 'true'
      @env.respond_to?(:test).should be_true
    end

    it 'returns false for items not in hash' do
      @env.respond_to?(:test).should be_false
    end

    it 'returns true for items in the config hash' do
      @env['config'] = {'test' => true}
      @env.respond_to?(:test).should be_true
    end

    it 'returns false for items not in the config hash' do
      @env['config'] = {}
      @env.respond_to?(:test).should be_false
    end

    it 'delegates if not found' do
      @env.respond_to?(:[]).should be_true
    end
  end
end
