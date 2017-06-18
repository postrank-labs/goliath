require 'spec_helper'
require 'goliath/server'

describe Goliath::Server do
  before(:each) do
    @s = Goliath::Server.new
  end

  describe 'defaults' do
    it 'to any interface' do
      expect(@s.address).to eq('0.0.0.0')
    end

    it 'to port 9000' do
      expect(@s.port).to eq(9000)
    end
  end

  describe 'configuration' do
    it 'accepts an address and port' do
      @s = Goliath::Server.new('10.2.1.1', 2020)
      expect(@s.address).to eq('10.2.1.1')
      expect(@s.port).to eq(2020)
    end

    it 'accepts a logger' do
      logger = double('logger')
      @s.logger = logger
      expect(@s.logger).to eq(logger)
    end

    it 'accepts an app' do
      app = double('app')
      @s.app = app
      expect(@s.app).to eq(app)
    end

    it 'accepts config' do
      config = double('config')
      @s.config = config
      expect(@s.config).to eq(config)
    end
  end

  describe 'startup' do
    before(:each) do
      expect(EM).to receive(:synchrony).and_yield
    end

    it 'starts' do
      addr = '10.2.1.1'
      port = 10000

      expect(EM).to receive(:start_server).with(addr, port, anything)

      @s.address = addr
      @s.port = port
      @s.start
    end

    it 'provides the app to each connection' do
      app = double('application')

      conn = double("connection").as_null_object
      expect(conn).to receive(:app=).with(app)

      expect(EM).to receive(:start_server).and_yield(conn)

      @s.app = app
      @s.start
    end

    it 'provides the logger to each connection' do
      logger = double('logger')

      conn = double("connection").as_null_object
      expect(conn).to receive(:logger=).with(logger)

      expect(EM).to receive(:start_server).and_yield(conn)

      @s.logger = logger
      @s.start
    end

    it 'provides the status object to each connection' do
      status = double('status')

      conn = double("connection").as_null_object
      expect(conn).to receive(:status=).with(status)

      expect(EM).to receive(:start_server).and_yield(conn)

      @s.status = status
      @s.start
    end

    it 'loads the config for each connection' do
      conn = double("connection").as_null_object
      expect(EM).to receive(:start_server).and_yield(conn)

      expect(@s).to receive(:load_config)
      @s.start
    end
  end

  context 'config parsing' do
    context 'environment' do
      after(:all) do
        # Be sure to revert to correct env
        Goliath.env = :test
      end
      it 'executes the block if the environment matches the provided string' do
        Goliath.env = :development
        block_run = false
        @s.environment('development') { block_run = true }
        expect(block_run).to be true
      end

      it 'does not execute the block if the environment does not match' do
        Goliath.env = :development
        block_run = false
        @s.environment('test') { block_run = true }
        expect(block_run).to be false
      end

      it 'accepts an array of environments' do
        Goliath.env = :development
        block_run = false
        @s.environment(['development', 'test']) { block_run = true }
        expect(block_run).to be true
      end

      it 'does not run the block if the environment is not in the array' do
        Goliath.env = :production
        block_run = false
        @s.environment(['development', 'test']) { block_run = true }
        expect(block_run).to be false
      end
    end
  end
end
