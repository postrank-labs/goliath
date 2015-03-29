require 'spec_helper'
require 'goliath/runner'
require 'irb'

describe Goliath::Console do
  before(:each) do
    @server = Goliath::Server.new
  end

  describe 'run!' do
    it "starts a irb session" do
      expect(Object).to receive(:send).with(:define_method, :goliath_server)
      expect(IRB).to receive(:start)
      expect(@server).to receive(:load_config)
      Goliath::Console.run!(@server)
    end
  end
end
