require 'spec_helper'
require 'goliath/api'

describe Goliath::API do

  DummyApi = Class.new(Goliath::API)

  describe "middlewares" do
    it "doesn't change after multi calls" do
      2.times { expect(DummyApi.middlewares.size).to eq(2) }
    end
  end
end
