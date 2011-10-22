#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
require 'goliath/websocket'
require 'goliath/rack/templates'

require 'pp'

class WebsocketEndPoint < Goliath::WebSocket
  def on_open(env)
    env.logger.info("WS OPEN")
    env['subscription'] = env.channel.subscribe { |m| env.stream_send(m) }
  end

  def on_message(env, msg)
    env.logger.info("WS MESSAGE: #{msg}")
    env.channel << msg
  end

  def on_close(env)
    env.logger.info("WS CLOSED")
    env.channel.unsubscribe(env['subscription'])
  end

  def on_error(env, error)
    env.logger.error error
  end
end

class WSInfo < Goliath::API
  include Goliath::Rack::Templates

  def response(env)
    [200, {}, erb(:index, :views => Goliath::Application.root_path('ws'))]
  end
end

class Websocket < Goliath::API
  use Goliath::Rack::Favicon, File.expand_path(File.dirname(__FILE__) + '/ws/favicon.ico')

  get '/', WSInfo
  map '/ws', WebsocketEndPoint
end
