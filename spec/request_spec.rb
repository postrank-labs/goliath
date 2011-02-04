require 'spec_helper'
require 'goliath/request'

describe Goliath::Request do
  before(:each) do
    @r = Goliath::Request.new
  end

  it 'sets up the default rack environment' do
    env = @r.env
    env['SERVER_SOFTWARE'].should == 'Goliath'
    env['SERVER_NAME'].should == 'localhost'
    env['rack.input'].should_not be_nil
    env['rack.version'].should == [1, 0]
    env['rack.errors'].should_not be_nil
    env['rack.multithread'].should be_false
    env['rack.multiprocess'].should be_false
    env['rack.run_once'].should be_false
  end

  it 'accepts a remote address' do
    @r.remote_address = '10.2.1.1'
    @r.remote_address.should == '10.2.1.1'
  end

  it 'accepts an async callback' do
    @r.async_callback = 'test'
    @r.async_callback.should == 'test'
    @r.async_close.should_not be_nil
  end

  it 'accepts a logger' do
    @r.logger = 'test'
    @r.logger.should == 'test'
  end

  it 'accepts a status object' do
    @r.status = 'status'
    @r.status.should == 'status'
  end

  it 'accepts a config object' do
    @r.config = 'config'
    @r.config.should == 'config'
  end

  it 'returns the content length' do
    @r.env['CONTENT_LENGTH'] = 42
    @r.content_length.should == 42
  end

  describe 'finished?' do
    # it 'returns true if we have finished parsing' do
    #   parser_mock = mock('parser')
    #
    #   @r.should_receive(:parser).and_return(parser_mock)
    #
    #   body_mock = mock('body')
    #   body_mock.should_receive(:size).and_return(42)
    #   @r.body = body_mock
    #
    #   @r.env['CONTENT_LENGTH'] = 42
    #   @r.finished?.should be_true
    # end

    it "returns false if the headers aren't finished" do
      @r.finished?.should be_false
    end

    # it "returns false if the body isn't finished" do
    #   parser_mock = mock('parser')
    #
    #   body_mock = mock('body')
    #   body_mock.should_receive(:size).and_return(42)
    #   @r.body = body_mock
    #
    #   @r.env['CONTENT_LENGTH'] = 52
    #   @r.finished?.should be_false
    # end
  end
end