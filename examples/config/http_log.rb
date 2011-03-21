config['forwarder'] = 'http://localhost:8080'

environment(:development) do
  config['mongo'] = EventMachine::Synchrony::ConnectionPool.new(size: 20) do
    # Need to deal with this just never connecting ... ?
    conn = EM::Mongo::Connection.new('localhost', 27017, 1, {:reconnect_in => 1})
    conn.db('http_log').collection('aggregators')
  end
end
