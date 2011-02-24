require 'spec_helper'

require 'em-synchrony'
require 'em-synchrony/em-http'

require 'rack'
require 'goliath'
require 'yajl'

class Interleaving < Goliath::API
  use Goliath::Rack::Params

  def response(env)
    f = Fiber.current
    delay = env.params['delay'].to_f
    EM.add_timer(delay) { f.resume }
    Fiber.yield

    [200, {}, delay.to_s]
  end
end

describe 'HTTP Pipelining support' do
  let(:app) do
    ::Rack::Builder.new do
      Interleaving.middlewares.each do |mw|
        use(*(mw[0..1].compact), &mw[2])
      end
      run Interleaving.new
    end
  end

  let(:server) do
    s = Goliath::Server.new
    s.logger = mock('log').as_null_object
    s.app = app
    s.start
  end

  it 'serves multiple requests via single connection' do
    EM.synchrony do
      server

      start = Time.now.to_f
      res = []

      conn = EM::HttpRequest.new('http://localhost:9000')
      r1 = conn.aget :query => {:delay => 0.3}, :keepalive => true
      r2 = conn.aget :query => {:delay => 0.2}

      r1.errback  { fail }
      r1.callback do |c|
        res << c.response
        c.response.should match('0.3')
      end

      r2.errback  { fail }
      r2.callback do |c|
        res << c.response

        res.should == ['0.3', '0.2']
        (Time.now.to_f - start).should be_within(0.1).of(0.3)

        EM.stop
      end
    end
  end

end