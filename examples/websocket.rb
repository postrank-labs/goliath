#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'bundler'
Bundler.setup

require 'goliath'
require 'goliath/websocket'

require 'yajl'
require 'pp'

class Websocket < Goliath::WebSocket
  use ::Rack::Reloader, 0 if Goliath.dev?

  def on_open(env)
    env.logger.info "WS OPEN"
  end

  def on_message(env, msg)
    env.logger.info "WS MESSAGE: #{msg}"

    env.stream_send("Goliath welcomes you #{msg}")
  end

  def on_close(env)
    env.logger.info "WS CLOSED"
  end

  def on_error(env, error)
    env.logger.error error
  end
end
