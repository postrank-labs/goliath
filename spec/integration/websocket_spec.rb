require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/test_helper_ws')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/websocket')

class WebSocketEndPoint < Goliath::WebSocket
  def on_open(env)
  end

  def on_error(env, error)
    env.logger.error error
  end

  def on_message(env, msg)
    env.stream_send(msg)
  end

  def on_close(env)
  end
end

describe "WebSocket" do
  include Goliath::TestHelper

  let(:err) { Proc.new { |c| fail "HTTP Request failed #{c.response}" } }

  it "should accept connection" do
    with_api(WebSocketEndPoint, {:verbose => true, :log_stdout => true}) do |server|
      expect_any_instance_of(WebSocketEndPoint).to receive(:on_open)
      ws_client_connect('/ws')
    end
  end

  it "should accept traffic" do
    with_api(WebSocketEndPoint, {:verbose => true, :log_stdout => true}) do |server|
      ws_client_connect('/ws') do |client|
        client.send "hello"
        expect(client.receive.data).to eq("hello")
      end
    end
  end
end


