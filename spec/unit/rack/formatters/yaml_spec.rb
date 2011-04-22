require 'spec_helper'
require 'goliath/rack/formatters/yaml'

describe Goliath::Rack::Formatters::YAML do
  it 'accepts an app' do
    lambda { Goliath::Rack::Formatters::YAML.new('my app') }.should_not raise_error
  end

  describe 'with a formatter' do
    before(:each) do
      @app = mock('app').as_null_object
      @ym = Goliath::Rack::Formatters::YAML.new(@app)
    end

    it 'checks content type for text/yaml' do
      @ym.yaml_response?({'Content-Type' => 'text/yaml'}).should be_true
    end

    it 'returns false for non-applicaton/yaml types' do
      @ym.yaml_response?({'Content-Type' => 'application/xml'}).should be_false
    end

    it 'calls the app with the provided environment' do
      env_mock = mock('env').as_null_object
      @app.should_receive(:call).with(env_mock).and_return([200, {}, {"a" => 1}])
      @ym.call(env_mock)
    end

    it 'formats the body into yaml if content-type is yaml' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'text/yaml'}, {:a => 1, :b => 2}])

      status, header, body = @ym.call({})
      lambda { YAML.load(body.first)[:a].should == 1 }.should_not raise_error
    end

    it "doesn't format to yaml if the type is not text/yaml" do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      YAML.should_not_receive(:encode)
      status, header, body = @ym.call({})
      body[:a].should == 1
    end

    it 'returns the status and headers' do
      @app.should_receive(:call).and_return([200, {'Content-Type' => 'application/xml'}, {:a => 1, :b => 2}])

      YAML.should_not_receive(:encode)
      status, header, body = @ym.call({})
      status.should == 200
      header.should == {'Content-Type' => 'application/xml'}
    end
  end
end
