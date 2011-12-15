require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/websocket')

class WebSocketEndPoint < Goliath::WebSocket
  def on_open(env)
    puts "FRED !!"
  end
end

class DummyServer < Goliath::API
end

describe "WebSocket" do
  include Goliath::TestHelper

  let(:err) { Proc.new { |c| fail "HTTP Request failed #{c.response}" } }

  it "should accept connection" do
    with_api(DummyServer, {:verbose => true, :log_file => "test.log"}) do |server|
#      wsendpoint = mock('wsendpoint').as_null_object
      wsendpoint = WebSocketEndPoint.new
      server.api.class.map '/ws', wsendpoint
      wsendpoint.should_receive(:on_open)
      puts "FRED: before client connect"
      ws_client_connect('/ws') do |client|
        client.send "foo"
      end
    end

  end
end


