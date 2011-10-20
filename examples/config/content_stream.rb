require 'amqp'

config['channel'] = EM::Channel.new

amqp_config = {
  :host => 'localhost',
  :user => 'test',
  :pass => 'test',
  :vhost => '/test'
}

conn = AMQP.connect(amqp_config)
xchange = AMQP::Channel.new(conn).fanout('stream')

q = AMQP::Channel.new(conn).queue('stream/StreamAPI')
q.bind(xchange)

def handle_message(metadata, payload)
  config['channel'].push(payload)
end

q.subscribe(&method(:handle_message))

# push data into the stream. (Just so we have stuff going in)
count = 0
EM.add_periodic_timer(2) do
  xchange.publish("Iteration #{count}\n")
  count += 1
end