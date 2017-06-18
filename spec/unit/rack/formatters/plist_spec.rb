require 'spec_helper'
require 'goliath/rack/formatters/plist'

describe Goliath::Rack::Formatters::PLIST do
  # this sucks, but I had install problems with nokogiri-plist
  # and I would rather not use an alternative library that requires libxml or rexml
  before(:all) do
    class Object
      def to_plist(*args) "plist: #{to_s}" end
    end
  end

  after(:all) do
    class Object
      undef to_plist
    end
  end

  it 'accepts an app' do
    expect { Goliath::Rack::Formatters::PLIST.new('my app') }.not_to raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = double('app').as_null_object
      @m = Goliath::Rack::Formatters::PLIST.new(@app)
    end

    it 'formats the body into plist if content-type is plist' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/x-plist'}, {:a => 1, :b => 2}])

      status, header, body = @m.call({})
      expect(body).to eq(["plist: {:a=>1, :b=>2}"])
    end

    it "doesn't format to plist if the type is not plist" do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])
      status, header, body = @m.call({})
      expect(status).to eq(200)
      expect(header).to eq({'Content-Type' => 'application/xml'})

      expect(body[:a]).to eq(1)
    end

    it 'returns the status and headers' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      status, header, body = @m.call({})
    end
  end
end
