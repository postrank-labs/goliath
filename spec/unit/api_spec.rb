require 'spec_helper'
require 'goliath/api'

describe Goliath::API do

  DummyApi = Class.new(Goliath::API)

  describe "middlewares" do
    it "doesn't change after multi calls" do
      2.times { DummyApi.should have(2).middlewares }
    end

    it "should include all middlewares from superclasses" do
      c1 = Class.new(Goliath::API) do
        use Goliath::Rack::Params
      end

      c2 = Class.new(c1) do
        use Goliath::Rack::DefaultMimeType
      end

      base_middlewares = DummyApi.middlewares
      middlewares = c2.middlewares - base_middlewares

      middlewares.size.should == 2
      middlewares[0][0].should == Goliath::Rack::Params
      middlewares[1][0].should == Goliath::Rack::DefaultMimeType
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
