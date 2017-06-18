require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/early_abort')

describe EarlyAbort do
  let(:err) { Proc.new { fail "API request failed" } }

  after do
    File.unlink(EarlyAbort::TEST_FILE) if File.exist?(EarlyAbort::TEST_FILE)
  end

  it "should return OK" do
    with_api(EarlyAbort) do
      get_request({}, err) do |c|
        expect(c.response).to eq("OK")
      end
    end
  end

  it 'fails without going in the response method if exception is raised in on_header hook' do
    with_api(EarlyAbort) do
      request_data = {
        :body => "a" * 20,
        :head => {'X-Crash' => 'true'}
      }

      post_request(request_data, err) do |c|
        expect(c.response).to eq("{\"error\":\"Can't handle requests with X-Crash: true.\"}")
        expect(File.exist?("/tmp/goliath-test-error.log")).to be false
      end
    end
  end

  it 'fails without going in the response method if exception is raised in on_body hook' do
    with_api(EarlyAbort) do
      request_data = { :body => "a" * 20 }

      post_request(request_data, err) do |c|
        expect(c.response).to match(/Payload size can't exceed 10 bytes/)
        expect(File.exist?("/tmp/goliath-test-error.log")).to be false
      end
    end
  end
end
