require 'spec_helper'
require 'json'

class ValidSingleParam < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Validation::RequiredParam, {:key => 'test'}

  # If you are using Golaith version <=0.9.1 you need to use Goliath::Rack::ValidationError
  # to prevent the request from remaining open after an error occurs
  #use Goliath::Rack::ValidationError

  def response(env)
    [200, {}, 'OK']
  end
end


class ValidNestedParams < Goliath::API
  use Goliath::Rack::Params

  # For this validation to pass you need to have this as parameter (json body here)
  # {
  #   'data' : {
  #     'login' : 'my_login'
  #   }
  # }
  #
  use Goliath::Rack::Validation::RequiredParam, :key => %w(data login)

  def response(env)
    [200, {}, 'OK']
  end
end

describe ValidSingleParam do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'returns OK with param' do
    with_api(ValidSingleParam) do
      get_request({:query => {:test => 'test'}}, err) do |c|
        expect(c.response).to eq('OK')
      end
    end
  end

  it 'returns error without param' do
    with_api(ValidSingleParam) do
      get_request({}, err) do |c|
        expect(c.response).to eq('[:error, "test identifier missing"]')
      end
    end
  end
end

class ValidationErrorInEndpoint < Goliath::API
  def response(env)
    raise Goliath::Validation::Error.new(420, 'You Must Chill', {'Foo' => 'Bar'})
  end
end

describe ValidationErrorInEndpoint do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'handles Goliath::Validation::Error correctly' do
    with_api(ValidationErrorInEndpoint) do
      get_request({}, err) do |c|
        expect(c.response).to eq('[:error, "You Must Chill"]')
        expect(c.response_header.status).to eq(420)
        expect(c.response_header["Foo"]).to eq('Bar')
      end
    end
  end
end

class ValidationErrorWhileParsing < Goliath::API
  def on_headers(env, headers)
    raise Goliath::Validation::Error.new(420, 'You Must Chill', {'Foo' => 'Bar'})
  end
end

describe ValidationErrorWhileParsing do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'handles Goliath::Validation::Error correctly' do
    with_api(ValidationErrorInEndpoint) do
      get_request({}, err) do |c|
        expect(c.response).to eq('[:error, "You Must Chill"]')
        expect(c.response_header.status).to eq(420)
        expect(c.response_header["Foo"]).to eq('Bar')
      end
    end
  end
end
