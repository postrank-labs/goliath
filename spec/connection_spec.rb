require 'spec_helper'
require 'goliath/connection'

describe Goliath::Connection do
  before(:each) do
    @c = Goliath::Connection.new('blah')
  end

  describe 'configuration' do
    it 'accepts an app' do
      app = mock('app')
      @c.app = app
      @c.app.should == app
    end

    it 'accepts a logger' do
      logger = mock('logger')
      @c.logger = logger
      @c.logger.should == logger
    end

    it 'accepts a status object' do
      status = mock('status')
      @c.status = status
      @c.status.should == status
    end

    it 'accepts config' do
      config = mock('config')
      @c.config = config
      @c.config.should == config
    end
  end

  describe 'post_init' do
    it 'sets up the request' do
      @c.post_init
      @c.request.should_not be_nil
    end

    it 'sets the logger into the request env' do
      @c.post_init
      @c.logger = 'logger'
      @c.request.logger.should == @c.logger
    end

    it 'sets the status object into the request env' do
      @c.post_init
      @c.status = 'status'
      @c.request.status.should == @c.status
    end

    it 'sets the config into the request env' do
      @c.post_init
      @c.config = 'config'
      @c.request.config.should == @c.config
    end

    it 'sets up the response' do
      @c.post_init
      @c.response.should_not be_nil
    end
  end

  describe 'receive_data' do
    it 'processes when all data is received' do
      request_mock = mock("request").as_null_object
      request_mock.should_receive(:finished?).and_return(true)

      @c.request = request_mock
      @c.should_receive(:process)
      @c.receive_data('more_data')
    end

    it "doesn't process if not finished receiving data" do
      request_mock = mock("request").as_null_object
      request_mock.should_receive(:finished?).and_return(false)

      @c.request = request_mock
      @c.should_not_receive(:process)
      @c.receive_data('more_data')
    end

    it "handles an invalid request" do
      request_mock = mock("request").as_null_object
      request_mock.should_receive(:finished?).and_raise(Goliath::InvalidRequest)

      @c.logger = mock("logger").as_null_object
      @c.request = request_mock
      lambda { @c.receive_data('more_data') }.should_not raise_error
    end
  end

  describe 'process' do
    it 'sets the remote address' do
      app_mock = mock('app').as_null_object
      addr = mock('address')
      request = Goliath::Request.new

      @c.should_receive(:remote_address).and_return(addr)
      @c.app = app_mock
      @c.post_init
      @c.logger= mock('logger').as_null_object
      @c.stub!(:post_process)
      @c.process

      @c.request.remote_address.should == addr
    end

    it 'sets the callback' do
      app_mock = mock('app').as_null_object
      request = Goliath::Request.new

      @c.post_init
      @c.app = app_mock
      @c.stub!(:remote_address)
      @c.stub!(:post_process)
      @c.logger= mock('logger').as_null_object
      @c.process

      @c.request.async_callback.should_not be_nil
    end

    it 'executes the application' do
      app_mock = mock('app').as_null_object
      request = Goliath::Request.new

      app_mock.should_receive(:call).with(request.env)

      @c.request = request
      @c.app = app_mock
      @c.stub!(:remote_address)
      @c.stub!(:post_process)
      @c.logger= mock('logger').as_null_object
      @c.process
    end

    it 'post processes the results' do
      app_mock = mock('app').as_null_object
      request = Goliath::Request.new

      @c.request = request
      @c.app = app_mock
      @c.stub!(:remote_address)
      @c.should_receive(:post_process)
      @c.logger= mock('logger').as_null_object
      @c.process
    end
  end

  describe 'async_response?' do
    it 'returns true for an async response' do
      @c.async_response?([-1, nil, nil]).should be_true
    end

    it 'returns false for a non-async response' do
      @c.async_response?([400, nil, nil]).should be_false
    end
  end
end
