require 'spec_helper'

describe Goliath::Connection do
  before(:each) do
    @c = Goliath::Connection.new('blah')
  end

  describe 'configuration' do
    it 'accepts an app' do
      app = double('app')
      @c.app = app
      expect(@c.app).to eq(app)
    end

    it 'accepts a logger' do
      logger = double('logger')
      @c.logger = logger
      expect(@c.logger).to eq(logger)
    end

    it 'accepts a status object' do
      status = double('status')
      @c.status = status
      expect(@c.status).to eq(status)
    end

    it 'accepts config' do
      config = double('config')
      @c.config = config
      expect(@c.config).to eq(config)
    end
  end

  describe 'post_init' do
    it 'sets up the parser' do
      @c.post_init
      expect(@c.instance_variable_get("@parser")).not_to be_nil
    end
  end

  describe 'receive_data' do
    it 'passes data to the http parser' do
      request_mock = double("parser").as_null_object
      expect(request_mock).to receive(:<<)

      current_mock = double("current").as_null_object

      @c.instance_variable_set("@parser", request_mock)
      @c.instance_variable_set("@current", current_mock)
      @c.receive_data('more_data')
    end

    it "closes the connection when a parse error is received" do
      current_mock = double("current").as_null_object
      expect(current_mock).to receive(:close)

      @c.instance_variable_set("@current", current_mock)
      expect { @c.receive_data("bad data") }.not_to raise_error
    end
  end

end
