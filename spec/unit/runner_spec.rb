require 'spec_helper'
require 'goliath/runner'

describe Goliath::Runner do
  before(:each) do
    @r = Goliath::Runner.new([], nil)
    @r.stub(:store_pid)

    @log_mock = double('logger').as_null_object
    @r.stub(:setup_logger).and_return(@log_mock)
  end

  describe 'server execution' do
    describe 'daemonization' do
      it 'daemonizes if specified' do
        Process.should_receive(:fork)
        @r.daemonize = true
        @r.run
      end

      it "doesn't daemonize if not specified" do
        Process.should_not_receive(:fork)
        @r.should_receive(:run_server)
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
          @r.stub(:setup_file_logger)
        end

        it 'configures the logger' do
          log = @r.send(:setup_logger)
          log.should_not be_nil
        end

        [:debug, :warn, :info].each do |type|
          it "responds to #{type} messages" do
            log = @r.send(:setup_logger)
            log.respond_to?(type).should be_true
          end
        end

        describe 'log level' do
          before(:each) do
            FileUtils.stub(:mkdir_p)
          end

          it 'sets the default log level' do
            log = @r.send(:setup_logger)
            log.level.should == Log4r::INFO
          end

          it 'sets debug when verbose' do
            @r.verbose = true
            log = @r.send(:setup_logger)
            log.level.should == Log4r::DEBUG
          end
        end

        describe 'file logger' do
          it "doesn't configure by default" do
            @r.should_not_receive(:setup_file_logger)
            log = @r.send(:setup_logger)
          end

          it 'configures if -l is provided' do
            @r.should_receive(:setup_file_logger)
            @r.log_file = 'out.log'
            log = @r.send(:setup_logger)
          end
        end

        describe 'stdout logger' do
          it "doesn't configure by default" do
            @r.should_not_receive(:setup_stdout_logger)
            log = @r.send(:setup_logger)
          end

          it 'configures if -s is provided' do
            @r.should_receive(:setup_stdout_logger)
            @r.log_stdout = true
            log = @r.send(:setup_logger)
          end
        end

        describe "custom logger" do

          it "doesn't configure Log4r" do
            CustomLogger = Struct.new(:info, :debug, :error, :fatal)
            Log4r::Logger.should_not_receive(:new)
            @r.logger = CustomLogger.new
            log = @r.send(:setup_logger)
          end

        end
      end

      it 'creates the log dir if neeed' do
        Log4r::FileOutputter.stub(:new)
        log_mock = double('log').as_null_object

        FileUtils.should_receive(:mkdir_p).with('/my/log/dir')

        @r.log_file = '/my/log/dir/log.txt'
        @r.send(:setup_file_logger, log_mock, nil)
      end
    end

    it 'sets up the api if that implements the #setup method' do
      server_mock = double("Server").as_null_object
      server_mock.api.should_receive(:setup)

      Goliath::Server.stub(:new).and_return(server_mock)

      @r.stub(:load_config).and_return({})
      @r.send(:run_server)
    end

    it 'runs the server' do
      server_mock = double("Server").as_null_object
      server_mock.should_receive(:start)

      Goliath::Server.should_receive(:new).and_return(server_mock)

      @r.stub(:load_config).and_return({})
      @r.send(:run_server)
    end

    it 'configures the server' do
      server_mock = Goliath::Server.new
      server_mock.stub(:start)

      @r.app = 'my_app'

      Goliath::Server.should_receive(:new).and_return(server_mock)

      server_mock.should_receive(:logger=).with(@log_mock)
      server_mock.should_receive(:app=).with('my_app')

      @r.send(:run_server)
    end
  end
end

describe Goliath::EnvironmentParser do
  before(:each) do
    ENV['RACK_ENV'] = nil
  end

  it 'returns the default environment if no other options are set' do
    Goliath::EnvironmentParser.parse.should == Goliath::DEFAULT_ENV
  end

  it 'gives precendence to RACK_ENV over the default' do
    ENV['RACK_ENV'] = 'rack_env'
    Goliath::EnvironmentParser.parse.should == :rack_env
  end

  it 'gives precendence to command-line flag over RACK_ENV' do
    ENV['RACK_ENV'] = 'rack_env'
    args = %w{ -e flag_env }
    Goliath::EnvironmentParser.parse(args).should == :flag_env
  end
end
