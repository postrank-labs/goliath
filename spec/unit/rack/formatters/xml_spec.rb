require 'spec_helper'
require 'goliath/rack/formatters/xml'
require 'nokogiri'

describe Goliath::Rack::Formatters::XML do
  it 'accepts an app' do
    lambda { Goliath::Rack::Formatters::XML.new('my app') }.should_not raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = mock('app').as_null_object
      @xml = Goliath::Rack::Formatters::XML.new(@app)
    end

    it 'checks content type for application/xml' do
      @xml.xml_response?({'Content-Type' => 'application/xml'}).should be_true
    end

    it 'returns false for non-applicaton/xml types' do
      @xml.xml_response?({'Content-Type' => 'application/json'}).should be_false
    end

    it 'calls the app with the provided environment' do
      env_mock = mock('env').as_null_object
      @app.should_receive(:call).with(env_mock).and_return([200, {}, {"a" => 1}])
      @xml.call(env_mock)
    end

    it 'formats the body into xml if content-type is xml' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      status, header, body = @xml.call({})
      lambda { Nokogiri.parse(body.first).search('a').inner_text.should == '1' }.should_not raise_error
    end

    it 'generates arrays correctly' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, [1, 2]])

      status, header, body = @xml.call({})
      lambda {
        doc = Nokogiri.parse(body.first)
        doc.search('item').first.inner_text.should == '1'
        doc.search('item').last.inner_text.should == '2'
      }.should_not raise_error
    end

    it "doesn't format to xml if the type is not application/xml" do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/json'}, {:a => 1, :b => 2}])

      @xml.should_not_receive(:to_xml)
      status, header, body = @xml.call({})
      body[:a].should == 1
    end

    it 'returns the status and headers' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/json'}, {:a => 1, :b => 2}])

      @xml.should_not_receive(:to_xml)
      status, header, body = @xml.call({})
      status.should == 200
      header.should == {'Content-Type' => 'application/json'}
    end
  end
end

