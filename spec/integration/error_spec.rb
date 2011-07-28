require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/error')

describe Error do
  let(:err) { Proc.new { fail "API request failed" } }

  after do
    File.unlink(Error::TEST_FILE) if File.exist?(Error::TEST_FILE)
  end

  it "should return OK" do
    with_api(Error) do
      get_request({}, err) do |c|
        c.response.should == "OK"
      end
    end
  end
  
  # The following two tests are very brittle, since they depend on the speed
  # of the machine executing the test and the size of the incoming data
  # packets. I hope someone more knowledgeable will be able to refactor these
  # ;-)
  it 'fails without going in the response method if exception is raised in on_header hook' do
    with_api(Error) do
      request_data = {
        :body => (["abcd"] * 200_000).join,
        :head => {'X-Crash' => 'true'}
      }

      post_request(request_data, err) do |c|
        c.response.should == "{\"error\":\"Can't handle requests with X-Crash: true.\"}"
        File.exist?("/tmp/goliath-test-error.log").should be_false
      end
    end
  end
  
  it 'fails without going in the response method if exception is raised in on_body hook' do
    with_api(Error) do
      request_data = {
        :body => (["abcd"] * 200_000).join
      }

      post_request(request_data, err) do |c|
        c.response.should =~ /Payload size can't exceed 10 bytes/
        File.exist?("/tmp/goliath-test-error.log").should be_false
      end
    end
  end

end
