require 'spec_helper'
require 'goliath/api'

describe Goliath::API do

  DummyApi = Class.new(Goliath::API)

  describe 'middlewares' do
    it "doesn't change after multi calls" do
      2.times { Goliath::API.should have(2).middlewares }
    end
  end

  describe ".maps?" do
    context "when not using maps" do
      it "returns false" do
        DummyApi.maps?.should be_false
      end
    end

    context "when using maps" do
      it "returns true" do
        DummyApi.map "/foo"
        DummyApi.maps?.should be_true
      end
    end
  end


end
