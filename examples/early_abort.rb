#!/usr/bin/env ruby
$:<< '../lib' << 'lib'
require 'goliath'

class EarlyAbort < Goliath::API
  include Goliath::Validation

  MAX_SIZE = 10
  TEST_FILE = "/tmp/goliath-test-error.log"

  def on_headers(env, headers)
    env.logger.info 'received headers: ' + headers.inspect
    env['async-headers'] = headers

    if env['HTTP_X_CRASH'] && env['HTTP_X_CRASH'] == 'true'
      raise Goliath::Validation::NotImplementedError.new(
          "Can't handle requests with X-Crash: true.")
    end
  end

  def on_body(env, data)
    env.logger.info 'received data: ' + data
    (env['async-body'] ||= '') << data
    size = env['async-body'].size

    if size >= MAX_SIZE
      raise Goliath::Validation::BadRequestError.new(
          "Payload size can't exceed #{MAX_SIZE} bytes. Received #{size.inspect} bytes.")
    end
  end

  def on_close(env)
    env.logger.info 'closing connection'
  end

  def response(env)
    File.open(TEST_FILE, "w+") { |f| f << "response that should not be here\n"}
    [200, {}, "OK"]
  end
end
