require 'spec_helper'
require 'goliath/rack/validation_error'
require 'goliath/validation/standard_http_errors'

describe Goliath::Validation::Error do
  it 'defines exceptions for each standard error response' do
    lambda { Goliath::Validation::BadRequestError.new }.should_not raise_error
    Goliath::Validation::BadRequestError.should < Goliath::Validation::Error
  end

  it 'sets a default status code and message' do
    Goliath::Validation::NotFoundError.new.status_code.should == '404'
    Goliath::Validation::NotFoundError.new.message.should == 'Not Found'
  end
end

