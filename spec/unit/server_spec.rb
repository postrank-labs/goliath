require 'spec_helper'
require 'goliath/server'

describe Goliath::Server do
  before(:each) do
    @s = Goliath::Server.new
  end

  describe 'defaults' do
    it 'to any interface' do
      @s.address.should == '0.0.0.0'
    end

    it 'to port 9000' do
      @s.port.should == 9000
    end
  end

  describe 'configuration' do
    it 'accepts an address and port' do
      @s = Goliath::Server.new('10.2.1.1', 2020)
      @s.address.should == '10.2.1.1'
      @s.port.should == 2020
    end

    it 'accepts a logger' do
      logger = mock('logger')
      @s.logger = logger
      @s.logger.should == logger
    end

    it 'accepts an app' do
      app = mock('app')
      @s.app = app
      @s.app.should == app
    end

    it 'accepts config' do
      config = mock('config')
      @s.config = config
      @s.config.should == config
    end
  end

  describe 'startup' do
    before(:each) do
      EM.should_receive(:synchrony).and_yield
    end

    it 'starts' do
      addr = '10.2.1.1'
      port = 10000

      EM.should_receive(:start_server).with(addr, port, anything)

      @s.address = addr
      @s.port = port
      @s.start
    end

    it 'provides the app to each connection' do
      app = mock('application')

      conn = mock("connection").as_null_object
      conn.should_receive(:app=).with(app)

      EM.should_receive(:start_server).and_yield(conn)

      @s.app = app
      @s.start
    end

    it 'provides the logger to each connection' do
      logger = mock('logger')

      conn = mock("connection").as_null_object
      conn.should_receive(:logger=).with(logger)

      EM.should_receive(:start_server).and_yield(conn)

      @s.logger = logger
      @s.start
    end

    it 'provides the status object to each connection' do
      status = mock('status')

      conn = mock("connection").as_null_object
      conn.should_receive(:status=).with(status)

      EM.should_receive(:start_server).and_yield(conn)

      @s.status = status
      @s.start
    end

    it 'loads the config for each connection' do
      conn = mock("connection").as_null_object
      EM.should_receive(:start_server).and_yield(conn)

      @s.should_receive(:load_config)
      @s.start
    end
  end

  context 'config parsing' do
    context 'environment' do
      it 'executes the block if the environment matches the provided string' do
        Goliath.env = :development
        block_run = false
        @s.environment('development') { block_run = true }
        block_run.should be_true
      end

      it 'does not execute the block if the environment does not match' do
        Goliath.env = :development
        block_run = false
        @s.environment('test') { block_run = true }
        block_run.should be_false
      end

      it 'accepts an array of environments' do
        Goliath.env = :development
        block_run = false
        @s.environment(['development', 'test']) { block_run = true }
        block_run.should be_true
      end

      it 'does not run the block if the environment is not in the array' do
        Goliath.env = :production
        block_run = false
        @s.environment(['development', 'test']) { block_run = true }
        block_run.should be_false
      end
    end
  end
end
