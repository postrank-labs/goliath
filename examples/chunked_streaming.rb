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

class ChunkedStreaming < Goliath::API
  def on_close(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    i = 0
    pt = EM.add_periodic_timer(1) do
      env.chunked_stream_send("#{i}\n")
      i += 1
    end

    EM.add_timer(10) do
      pt.cancel

      env.chunked_stream_send("!! BOOM !!\n")
      env.chunked_stream_close
    end

    headers = { 'Content-Type' => 'text/plain', 'X-Stream' => 'Goliath' }
    chunked_streaming_response(200, headers)
  end
end
