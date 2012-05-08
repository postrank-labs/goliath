require 'spec_helper'
require 'goliath/api'

describe Goliath::API do

  DummyApi = Class.new(Goliath::API)

  describe "middlewares" do
    it "doesn't change after multi calls" do
      2.times { DummyApi.should have(2).middlewares }
    end
  end
end
