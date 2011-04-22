#
# Provides HTTP streaming using chunked transfer encoding
#
# http://en.wikipedia.org/wiki/Chunked_transfer_encoding
# http://developers.sun.com/mobility/midp/questions/chunking/
# http://blog.port80software.com/2006/11/08/
#
module Goliath
  class ChunkedStreamingAPI < Goliath::API
    CRLF = "\r\n"
    STREAMING_HEADERS = { 'Transfer-Encoding' => 'chunked' }

    # Sends a chunk in a Chunked transfer encoding stream.
    #
    #     Each chunk starts with the number of octets of the data it embeds expressed
    #     in hexadecimal followed by optional parameters (chunk extension) and a
    #     terminating CRLF (carriage return and line feed) sequence, followed by the
    #     chunk data. The chunk is terminated by CRLF. If chunk extensions are
    #     provided, the chunk size is terminated by a semicolon followed with the
    #     extension name and an optional equal sign and value
    #     (Note: chunk extensions aren't provided yet)
    #
    def send_chunk(env, chunk)
      chunk_len_in_hex = chunk.bytesize.to_s(16)
      body = [chunk_len_in_hex, CRLF, chunk, CRLF].join
      env.stream_send(body)
    end

    # Sends the terminating chunk in a chunked transfer encoding stream, and
    # closes the stream.
    #
    #     The last chunk is a zero-length chunk, with the chunk size coded as 0, but
    #     without any chunk data section.  The final chunk may be followed by an
    #     optional trailer of additional entity header fields that are normally
    #     delivered in the HTTP header to allow the delivery of data that can only
    #     be computed after all chunk data has been generated. The sender may
    #     indicate in a Trailer header field which additional fields it will send
    #     in the trailer after the chunks.
    #     (Note: trailer headers aren't provided yet
    #
    def close_stream(env)
      env.stream_send([0, CRLF, CRLF].join)
      env.stream_close
    end

  end
end
