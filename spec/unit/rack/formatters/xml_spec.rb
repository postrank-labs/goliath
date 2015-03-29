require 'spec_helper'
require 'goliath/rack/formatters/xml'
require 'nokogiri'

describe Goliath::Rack::Formatters::XML do
  it 'accepts an app' do
    expect { Goliath::Rack::Formatters::XML.new('my app') }.not_to raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = double('app').as_null_object
      @xml = Goliath::Rack::Formatters::XML.new(@app)
    end

    it 'checks content type for application/xml' do
      expect(@xml.xml_response?({'Content-Type' => 'application/xml'})).to be_truthy
    end

    it 'returns false for non-applicaton/xml types' do
      expect(@xml.xml_response?({'Content-Type' => 'application/json'})).to be_falsey
    end

    it 'calls the app with the provided environment' do
      env_mock = double('env').as_null_object
      expect(@app).to receive(:call).with(env_mock).and_return([200, {}, {"a" => 1}])
      @xml.call(env_mock)
    end

    it 'formats the body into xml if content-type is xml' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      status, header, body = @xml.call({})
      expect { expect(Nokogiri.parse(body.first).search('a').inner_text).to eq('1') }.not_to raise_error
    end

    it 'generates arrays correctly' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, [1, 2]])

      status, header, body = @xml.call({})
      expect {
        doc = Nokogiri.parse(body.first)
        expect(doc.search('item').first.inner_text).to eq('1')
        expect(doc.search('item').last.inner_text).to eq('2')
      }.not_to raise_error
    end

    it "doesn't format to xml if the type is not application/xml" do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/json'}, {:a => 1, :b => 2}])

      expect(@xml).not_to receive(:to_xml)
      status, header, body = @xml.call({})
      expect(body[:a]).to eq(1)
    end

    it 'returns the status and headers' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/json'}, {:a => 1, :b => 2}])

      expect(@xml).not_to receive(:to_xml)
      status, header, body = @xml.call({})
      expect(status).to eq(200)
      expect(header).to eq({'Content-Type' => 'application/json'})
    end
  end
end

