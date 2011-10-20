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

  describe 'parse_headers' do
    it 'sets content_type correctly' do
      parser = mock('parser').as_null_object

      @r.parse_header({'Content-Type' => 'text/plain'}, parser)
      @r.env['CONTENT_TYPE'].should == 'text/plain'
    end

    it 'sets content_length correctly' do
      parser = mock('parser').as_null_object

      @r.parse_header({'Content-Length' => 42}, parser)
      @r.env['CONTENT_LENGTH'].should == 42
    end

    it 'sets server_name and server_port correctly' do
      parser = mock('parser').as_null_object

      @r.parse_header({'Host' => 'myhost.com:3000'}, parser)
      @r.env['SERVER_NAME'].should == 'myhost.com'
      @r.env['SERVER_PORT'].should == '3000'
    end
  end
end
