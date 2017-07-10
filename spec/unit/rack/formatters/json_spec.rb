require 'spec_helper'
require 'goliath/rack/formatters/json'

describe Goliath::Rack::Formatters::JSON do
  it 'accepts an app' do
    expect { Goliath::Rack::Formatters::JSON.new('my app') }.not_to raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = double('app').as_null_object
      @js = Goliath::Rack::Formatters::JSON.new(@app)
    end

    it 'checks content type for application/json' do
      expect(@js.json_response?({'Content-Type' => 'application/json'})).to be_truthy
    end

    it 'checks content type for application/vnd.api+json' do
      expect(@js.json_response?({'Content-Type' => 'application/vnd.api+json'})).to be_truthy
    end

    it 'checks content type for application/javascript' do
      expect(@js.json_response?({'Content-Type' => 'application/javascript'})).to be_truthy
    end

    it 'returns false for non-applicaton/json types' do
      expect(@js.json_response?({'Content-Type' => 'application/xml'})).to be_falsey
    end

    it 'calls the app with the provided environment' do
      env_mock = double('env').as_null_object
      expect(@app).to receive(:call).with(env_mock).and_return([200, {}, {"a" => 1}])
      @js.call(env_mock)
    end

    it 'formats the body into json if content-type is json' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/json'}, {:a => 1, :b => 2}])

      status, header, body = @js.call({})
      expect { expect(MultiJson.load(body.first)['a']).to eq(1) }.not_to raise_error
    end

    it 'formats the body into json if content-type is vnd.api+json' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/vnd.api+json'}, {:a => 1, :b => 2}])

      status, header, body = @js.call({})
      expect { expect(MultiJson.load(body.first)['a']).to eq(1) }.not_to raise_error
    end

    it 'formats the body into json if content-type is javascript' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/javascript'}, {:a => 1, :b => 2}])

      status, header, body = @js.call({})
      expect { expect(MultiJson.load(body.first)['a']).to eq(1) }.not_to raise_error
    end

    it "doesn't format to json if the type is not application/json" do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      expect(MultiJson).not_to receive(:dump)
      status, header, body = @js.call({})
      expect(body[:a]).to eq(1)
    end

    it 'returns the status and headers' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      expect(MultiJson).not_to receive(:dump)
      status, header, body = @js.call({})
      expect(status).to eq(200)
      expect(header).to eq({'Content-Type' => 'application/xml'})
    end
  end
end

