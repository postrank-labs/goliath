require 'spec_helper'
require 'goliath/validation/standard_http_errors'

describe Goliath::Validation::Error do
  it 'defines exceptions for each standard error response' do
    lambda { Goliath::Validation::BadRequestError.new }.should_not raise_error
    Goliath::Validation::BadRequestError.should < Goliath::Validation::Error
  end

  it 'defines InternalServerError not InternalServerErrorError' do
    lambda { Goliath::Validation::InternalServerError.new }.should_not raise_error
    Goliath::Validation::InternalServerError.should < Goliath::Validation::Error
  end

  it 'sets a default status code and message' do
    nfe = Goliath::Validation::NotFoundError.new
    nfe.status_code.should == '404'
    nfe.message.should == 'Not Found'
  end
end

