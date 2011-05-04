require 'spec_helper'
require 'goliath/rack/formatters/plist'

describe Goliath::Rack::Formatters::Plist do
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
    lambda { Goliath::Rack::Formatters::Plist.new('my app') }.should_not raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = mock('app').as_null_object
      @m = Goliath::Rack::Formatters::Plist.new(@app)
    end

    it 'formats the body into plist if content-type is plist' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/x-plist'}, {:a => 1, :b => 2}])

      status, header, body = @m.call({})
      body.should == ["plist: {:a=>1, :b=>2}"]
    end

    it "doesn't format to plist if the type is not plist" do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])
      status, header, body = @m.call({})
      status.should == 200
      header.should == {'Content-Type' => 'application/xml'}

      body[:a].should == 1
    end

    it 'returns the status and headers' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      status, header, body = @m.call({})
    end
  end
end
