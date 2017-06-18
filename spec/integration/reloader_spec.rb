require 'spec_helper'

Goliath.env = :development

class ReloaderDev < Goliath::API
  use Goliath::Rack::Params
end

class ReloaderAlreadyLoaded < Goliath::API
  use ::Rack::Reloader, 0
  use Goliath::Rack::Params
end

class ReloaderProd < Goliath::API
end

describe "Reloader" do
  let(:err) { Proc.new { fail "API request failed" } }

  before(:each) { Goliath.env = :development }
  after(:each) { Goliath.env = :test }

  def count(klass)
    cnt = 0
    klass.middlewares.each do |mw|
      cnt += 1 if mw.first == ::Rack::Reloader
    end
    cnt
  end

  it 'adds reloader in dev mode' do
    expect(count(ReloaderDev)).to eq(1)
  end

  it "doesn't add if it's already there in dev mode" do
    expect(count(ReloaderAlreadyLoaded)).to eq(1)
  end

  it "doesn't add in prod mode" do
    Goliath.env = :production
    expect(count(ReloaderProd)).to eq(0)
  end
end
