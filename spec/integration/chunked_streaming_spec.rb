require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/test_helper_streaming')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath')

class ChunkedStreaming < Goliath::API

  def response(env)

    EM.next_tick do
      env.chunked_stream_send("chunked")
      env.chunked_stream_close
    end

    headers = { 'Content-Type' => 'text/plain', 'X-Stream' => 'Goliath' }
    chunked_streaming_response(200, headers)
  end

  def on_close(env)
  end
end

describe "ChunkedStreaming" do
  include Goliath::TestHelper

  let(:err) { Proc.new { |c| fail "HTTP Request failed #{c.response}" } }

  it "should stream content" do
    with_api(ChunkedStreaming, {:verbose => true, :log_stdout => true}) do |server|
      streaming_client_connect('/streaming') do |client|
        expect(client.receive).to eq("chunked")
      end
    end
  end
end


