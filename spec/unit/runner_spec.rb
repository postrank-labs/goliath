require 'spec_helper'
require 'goliath/runner'

describe Goliath::Runner do
  before(:each) do
    @r = Goliath::Runner.new([], nil)
    allow(@r).to receive(:store_pid)

    @log_mock = double('logger').as_null_object
    allow(@r).to receive(:setup_logger).and_return(@log_mock)
  end

  describe 'server execution' do
    describe 'daemonization' do
      it 'daemonizes if specified' do
        expect(Process).to receive(:fork)
        @r.daemonize = true
        @r.run
      end

      it "doesn't daemonize if not specified" do
        expect(Process).not_to receive(:fork)
        expect(@r).to receive(:run_server)
        @r.run
      end
    end

    describe 'logging' do
      before(:each) do
        @r = Goliath::Runner.new([], nil)
      end

      after(:each) do
        # Runner default env is development.
        # We do need to revert to test
        Goliath.env = :test
      end

      describe 'without setting up file logger' do
        before(:each) do
          allow(@r).to receive(:setup_file_logger)
        end

        it 'configures the logger' do
          log = @r.send(:setup_logger)
          expect(log).not_to be_nil
        end

        [:debug, :warn, :info].each do |type|
          it "responds to #{type} messages" do
            log = @r.send(:setup_logger)
            expect(log.respond_to?(type)).to be true
          end
        end

        describe 'log level' do
          before(:each) do
            allow(FileUtils).to receive(:mkdir_p)
          end

          it 'sets the default log level' do
            log = @r.send(:setup_logger)
            expect(log.level).to eq(Log4r::INFO)
          end

          it 'sets debug when verbose' do
            @r.verbose = true
            log = @r.send(:setup_logger)
            expect(log.level).to eq(Log4r::DEBUG)
          end
        end

        describe 'file logger' do
          it "doesn't configure by default" do
            expect(@r).not_to receive(:setup_file_logger)
            log = @r.send(:setup_logger)
          end

          it 'configures if -l is provided' do
            expect(@r).to receive(:setup_file_logger)
            @r.log_file = 'out.log'
            log = @r.send(:setup_logger)
          end
        end

        describe 'stdout logger' do
          it "doesn't configure by default" do
            expect(@r).not_to receive(:setup_stdout_logger)
            log = @r.send(:setup_logger)
          end

          it 'configures if -s is provided' do
            expect(@r).to receive(:setup_stdout_logger)
            @r.log_stdout = true
            log = @r.send(:setup_logger)
          end
        end

        describe "custom logger" do

          it "doesn't configure Log4r" do
            CustomLogger = Struct.new(:info, :debug, :error, :fatal)
            expect(Log4r::Logger).not_to receive(:new)
            @r.logger = CustomLogger.new
            log = @r.send(:setup_logger)
          end

        end
      end

      it 'creates the log dir if neeed' do
        allow(Log4r::FileOutputter).to receive(:new)
        log_mock = double('log').as_null_object

        expect(FileUtils).to receive(:mkdir_p).with('/my/log/dir')

        @r.log_file = '/my/log/dir/log.txt'
        @r.send(:setup_file_logger, log_mock, nil)
      end
    end

    it 'sets up the api if that implements the #setup method' do
      server_mock = double("Server").as_null_object
      expect(server_mock.api).to receive(:setup)

      allow(Goliath::Server).to receive(:new).and_return(server_mock)

      allow(@r).to receive(:load_config).and_return({})
      @r.send(:run_server)
    end

    it 'runs the server' do
      server_mock = double("Server").as_null_object
      expect(server_mock).to receive(:start)

      expect(Goliath::Server).to receive(:new).and_return(server_mock)

      allow(@r).to receive(:load_config).and_return({})
      @r.send(:run_server)
    end

    it 'configures the server' do
      server_mock = Goliath::Server.new
      allow(server_mock).to receive(:start)

      @r.app = 'my_app'

      expect(Goliath::Server).to receive(:new).and_return(server_mock)

      expect(server_mock).to receive(:logger=).with(@log_mock)
      expect(server_mock).to receive(:app=).with('my_app')

      @r.send(:run_server)
    end
  end
end

describe Goliath::EnvironmentParser do
  before(:each) do
    ENV['RACK_ENV'] = nil
  end

  it 'returns the default environment if no other options are set' do
    expect(Goliath::EnvironmentParser.parse).to eq(Goliath::DEFAULT_ENV)
  end

  it 'gives precendence to RACK_ENV over the default' do
    ENV['RACK_ENV'] = 'rack_env'
    expect(Goliath::EnvironmentParser.parse).to eq(:rack_env)
  end

  it 'gives precendence to command-line flag over RACK_ENV' do
    ENV['RACK_ENV'] = 'rack_env'
    args = %w{ -e flag_env }
    expect(Goliath::EnvironmentParser.parse(args)).to eq(:flag_env)
  end
end
