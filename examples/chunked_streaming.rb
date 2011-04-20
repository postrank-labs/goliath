#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

#
# A simple HTTP streaming API which returns a 200 response for any GET request
# and then emits numbers 1 through 10 in 1 second intervals using Chunked
# transfer encoding, and finally closes the connection.
#
# Chunked transfer streaming works transparently with both browsers and
# streaming consumers.
#

require 'goliath'
require 'goliath/chunked_streaming_api'

class ChunkedStreaming < Goliath::ChunkedStreamingAPI
  def on_close(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    i = 0
    pt = EM.add_periodic_timer(1) do
      send_chunk(env, "#{i}\n")
      i += 1
    end

    EM.add_timer(10) do
      pt.cancel

      send_chunk(env, "!! BOOM !!\n")
      close_stream(env)
    end

    headers = { 'Content-Type' => 'text/plain', 'X-Stream' => 'Goliath' }
    [200, STREAMING_HEADERS.merge(headers), STREAMING]
  end
end
