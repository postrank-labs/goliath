require 'spec_helper'
require 'goliath/validation/standard_http_errors'

describe Goliath::Validation::Error do
  it 'defines exceptions for each standard error response' do
    expect { Goliath::Validation::BadRequestError.new }.not_to raise_error
    expect(Goliath::Validation::BadRequestError).to be < Goliath::Validation::Error
  end

  it 'defines InternalServerError not InternalServerErrorError' do
    expect { Goliath::Validation::InternalServerError.new }.not_to raise_error
    expect(Goliath::Validation::InternalServerError).to be < Goliath::Validation::Error
  end

  it 'sets a default status code and message' do
    nfe = Goliath::Validation::NotFoundError.new
    expect(nfe.status_code).to eq('404')
    expect(nfe.message).to eq('Not Found')
  end
end

