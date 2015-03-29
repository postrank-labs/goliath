require 'spec_helper'
require 'goliath/rack/formatters/yaml'

describe Goliath::Rack::Formatters::YAML do
  it 'accepts an app' do
    expect { Goliath::Rack::Formatters::YAML.new('my app') }.not_to raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = double('app').as_null_object
      @ym = Goliath::Rack::Formatters::YAML.new(@app)
    end

    it 'checks content type for text/yaml' do
      expect(@ym.yaml_response?({'Content-Type' => 'text/yaml'})).to be_truthy
    end

    it 'returns false for non-applicaton/yaml types' do
      expect(@ym.yaml_response?({'Content-Type' => 'application/xml'})).to be_falsey
    end

    it 'calls the app with the provided environment' do
      env_mock = double('env').as_null_object
      expect(@app).to receive(:call).with(env_mock).and_return([200, {}, {"a" => 1}])
      @ym.call(env_mock)
    end

    it 'formats the body into yaml if content-type is yaml' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'text/yaml'}, {:a => 1, :b => 2}])

      status, header, body = @ym.call({})
      expect { expect(YAML.load(body.first)[:a]).to eq(1) }.not_to raise_error
    end

    it "doesn't format to yaml if the type is not text/yaml" do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      expect(YAML).not_to receive(:encode)
      status, header, body = @ym.call({})
      expect(body[:a]).to eq(1)
    end

    it 'returns the status and headers' do
      expect(@app).to receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      expect(YAML).not_to receive(:encode)
      status, header, body = @ym.call({})
      expect(status).to eq(200)
      expect(header).to eq({'Content-Type' => 'application/xml'})
    end
  end
end
