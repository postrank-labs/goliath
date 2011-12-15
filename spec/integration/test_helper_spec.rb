require 'spec_helper'

class DummyServer < Goliath::API

end

describe "with_api" do
 let(:err) { Proc.new { fail "API request failed" } }

  it "should log in file if requested" do
    with_api(DummyServer, :log_file => "test.log") do |api|
      get_request({},err)
    end
    File.exist?("test.log").should be_true
  end

  it "should log on console if requested" do
    with_api(DummyServer, :log_stdout) do |api|
      get_request({},err)
    end
  end


end
