require 'spec_helper'
require 'goliath/rack/validation/request_method'

describe Goliath::Rack::Validation::RequestMethod do
  before(:each) do
    @app_headers = {'Content-Type' => 'asdf'}
    @app_body = {'a' => 'b'}

    @app = double('app').as_null_object
    allow(@app).to receive(:call).and_return([200, @app_headers, @app_body])
  end

  it 'accepts an app' do
    expect { Goliath::Rack::Validation::RequestMethod.new('my app') }.not_to raise_error
  end

  describe 'with defaults' do
    before(:each) do
      @env = {}
      @rm = Goliath::Rack::Validation::RequestMethod.new(@app, ['GET', 'POST'])
    end

    it 'raises error if method is invalid' do
      @env['REQUEST_METHOD'] = 'fubar'
      expect(@rm.call(@env)).to eq([405, {'Allow' => 'GET, POST'}, {:error => "Invalid request method"}])
    end

    it 'allows valid methods through' do
      @env['REQUEST_METHOD'] = 'GET'
      expect(@rm.call(@env)).to eq([200, @app_headers, @app_body])
    end

    it 'returns app status, headers and body' do
      @env['REQUEST_METHOD'] = 'POST'

      status, headers, body = @rm.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq(@app_headers)
      expect(body).to eq(@app_body)
    end
  end

  it 'accepts methods on initialize' do
    rm = Goliath::Rack::Validation::RequestMethod.new('my app', ['GET', 'DELETE', 'HEAD'])
    expect(rm.methods).to eq(['GET', 'DELETE', 'HEAD'])
  end

  it 'accepts string method on initialize' do
    rm = Goliath::Rack::Validation::RequestMethod.new('my app', 'GET')
    expect(rm.methods).to eq(['GET'])
  end
end
