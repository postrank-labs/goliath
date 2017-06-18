require 'spec_helper'
require 'goliath/env'

describe Goliath::Env do
  before(:each) do
    @env = Goliath::Env.new
  end

  it 'responds to []=' do
    expect { @env['test'] = 'blah' }.not_to raise_error
  end

  it 'responds to []' do
    @env['test'] = 'blah'
    expect { expect(@env['test']).to eq('blah') }.not_to raise_error
  end

  context '#method_missing' do
    it 'allows access to items as methods' do
      @env['db'] = 'test'
      expect(@env.db).to eq('test')
    end

    it 'allows access to config items as methods' do
      @env['config'] = {}
      @env['config']['db'] = 'test'
      expect(@env.db).to eq('test')
    end
  end

  context '#respond_to?' do
    it 'returns true for items in the hash' do
      @env['test'] = 'true'
      expect(@env.respond_to?(:test)).to be true
    end

    it 'returns false for items not in hash' do
      expect(@env.respond_to?(:test)).to be false
    end

    it 'returns true for items in the config hash' do
      @env['config'] = {'test' => true}
      expect(@env.respond_to?(:test)).to be true
    end

    it 'returns false for items not in the config hash' do
      @env['config'] = {}
      expect(@env.respond_to?(:test)).to be false
    end

    it 'delegates if not found' do
      expect(@env.respond_to?(:[])).to be true
    end
  end
end
