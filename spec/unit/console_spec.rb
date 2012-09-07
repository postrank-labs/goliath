require 'spec_helper'
require 'goliath/runner'
require 'irb'

describe Goliath::Console do
  before(:each) do
    @server = Goliath::Server.new
  end

  describe 'run!' do
    it "starts a irb session" do
      Object.should_receive(:send).with(:define_method, :goliath_server)
      IRB.should_receive(:start)
      @server.should_receive(:load_config)
      Goliath::Console.run!(@server)
    end
  end
end
