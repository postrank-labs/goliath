require 'spec_helper'

class DummyServer < Goliath::API

end

describe "with_api" do
 let(:err) { Proc.new { fail "API request failed" } }

  it "should log in file if requested" do
    with_api(DummyServer, :log_file => "test.log") do |api|
      get_request({},err)
    end
    expect(File.exist?("test.log")).to be_truthy
    File.unlink("test.log")
  end

  it "should log on console if requested" do
    with_api(DummyServer, {:log_stdout => true }) do |api|
      expect(api.logger.outputters.select {|o| o.is_a? Log4r::StdoutOutputter}).not_to be_empty
      EM.stop
    end
  end

  it "should be verbose if asked" do
    with_api(DummyServer, {:verbose => true, :log_stdout => true }) do |api|
      expect(api.logger.level).to eq(Log4r::DEBUG)
      EM.stop
    end

  end

end
