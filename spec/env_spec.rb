require 'spec_helper'
require 'api/v3/lib/goliath/env'

describe Goliath::Env do
  before(:each) do
    @env = Goliath::Env.new
  end

  it 'responds to []=' do
    lambda { @env['test'] = 'blah' }.should_not raise_error(Exception)
  end

  it 'responds to []' do
    @env['test'] = 'blah'
    lambda { @env['test'].should == 'blah' }.should_not raise_error(Exception)
  end

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
