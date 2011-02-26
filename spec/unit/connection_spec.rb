require 'spec_helper'

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
    it 'sets up the parser' do
      @c.post_init
      @c.instance_variable_get("@parser").should_not be_nil
    end
  end

  describe 'receive_data' do
    it 'passes data to the http parser' do
      request_mock = mock("parser").as_null_object
      request_mock.should_receive(:<<)

      @c.instance_variable_set("@parser", request_mock)
      @c.receive_data('more_data')
    end

    it "closes the connection when a parse error is received" do
      current_mock = mock("current").as_null_object
      current_mock.should_receive(:close)

      @c.instance_variable_set("@current", current_mock)
      lambda { @c.receive_data("bad data") }.should_not raise_error
    end
  end

end
