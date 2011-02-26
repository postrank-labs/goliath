require 'spec_helper'

describe Goliath::Request do
  before(:each) do

    app = mock('app').as_null_object
    env = Goliath::Env.new

    @r = Goliath::Request.new(app, nil, env)
  end

  describe 'initialization' do

    it 'initializes env defaults' do
      env = Goliath::Env.new
      env['INIT'] = 'init'

      r = Goliath::Request.new(nil, nil, env)
      r.env['INIT'].should == 'init'
    end

    it 'initializes an async callback' do
      @r.env['async.callback'].should_not be_nil
    end

    it 'initializes request' do
      @r.instance_variable_get("@state").should == :processing
    end
  end

  describe 'process' do

    it 'executes the application' do
      app_mock = mock('app').as_null_object
      env_mock = mock('app').as_null_object
      request = Goliath::Request.new(app_mock, nil, env_mock)

      app_mock.should_receive(:call).with(request.env)
      request.should_receive(:post_process)

      request.process
    end

  end

  describe 'finished?' do
    it "returns false if the request parsing has not yet finished" do
      @r.finished?.should be_false
    end

    it 'returns true if we have finished request parsing' do
      @r.should_receive(:post_process).and_return(nil)
      @r.process

      @r.finished?.should be_true
    end

  end
end
