require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/test_helper_sse')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath')
require File.join(File.dirname(__FILE__), '../../', 'lib/goliath/api')

class EventStreamEndpoint < Goliath::API
  def self.events
    @events ||= EM::Queue.new
  end

  def response(env)
    self.class.events.pop do |event|
      payload = if event.key?(:name)
        "event: #{event[:name]}\ndata: #{event[:data]}\n\n"
      else
        "data: #{event[:data]}\n\n"
      end
      env.stream_send(payload)
    end
    streaming_response(200, 'Content-Type' => 'text/event-stream')
  end
end

describe 'EventStream' do
  include Goliath::TestHelper

  context 'named events' do
    it 'should accept stream' do
      with_api(EventStreamEndpoint, {:verbose => true, :log_stdout => true}) do |server|
        sse_client_connect('/stream') do |client|
          client.listen_to('custom_event')
          EM.add_timer(0.1) do
            EventStreamEndpoint.events.push(name: 'custom_event', data: 'content')
          end
          EM.add_timer(0.2) do
            client.received_on('custom_event').should == ['content']
            client.received.should == []
            stop
          end
        end
      end
    end
  end

  context 'unnamed events' do
    it 'should accept stream' do
      with_api(EventStreamEndpoint, {:verbose => true, :log_stdout => true}) do |server|
        sse_client_connect('/stream') do |client|
          EM.add_timer(0.1) do
            EventStreamEndpoint.events.push(data: 'content')
          end
          EM.add_timer(0.2) do
            client.received.should == ['content']
            stop
          end
        end
      end
    end
  end
end