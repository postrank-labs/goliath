require 'spec_helper'
require 'goliath/rack/validation_error'

describe Goliath::Rack::ValidationError do
  it 'accepts an app' do
    lambda { Goliath::Rack::ValidationError.new('my app') }.should_not raise_error(Exception)
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @ve = Goliath::Rack::ValidationError.new(@app)
    end

    it 'returns the apps status' do
      app_headers = {'Content-Type' => 'mine'}
      app_body = {'a' => 'b'}
      @app.should_receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @ve.call({})
      status.should == 200
      headers.should == app_headers
      body.should == app_body
    end

    it 'catches Goliath::Validation::Error' do
      @app.should_receive(:call).and_raise(Goliath::Validation::Error.new(401, 'my error'))
      lambda { @ve.call({}) }.should_not raise_error(Goliath::Validation::Error)
    end

    it 'returns an error response on exception' do
      @app.should_receive(:call).and_raise(Goliath::Validation::Error.new(401, 'my error'))
      status, headers, body = @ve.call({})

      status.should == 401
      headers.should == {}
      body.should == {:error => 'my error'}
    end
  end
end
