require 'spec_helper'
require 'goliath/api'

describe Goliath::API do
  describe 'middlewares' do
    it "doesn't change after multi calls" do
      2.times { Goliath::API.should have(2).middlewares }
    end
  end
end
