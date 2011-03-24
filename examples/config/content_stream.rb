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

# pull data off the exchange and push to streams
q.pop do |data|
  if data.nil?
    EM.add_timer(1) { q.pop }
  else
    config['channel'].push(data)
    q.pop
  end
end

# push data into the stream. (Just so we have stuff going in)
count = 0
EM.add_periodic_timer(2) do
  xchange.publish("Iteration #{count}\n")
  count += 1
end