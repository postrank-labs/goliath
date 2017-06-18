require 'spec_helper'

class Interleaving < Goliath::API
  use Goliath::Rack::Params

  def response(env)
    delay = env.params['delay']
    EM::Synchrony.sleep(delay.to_f)

    [200, {}, delay]
  end
end

describe 'HTTP Pipelining support' do
  it 'serves multiple requests via single connection' do
    with_api(Interleaving, :port => 9901) do
      start = Time.now.to_f
      res = []

      conn = EM::HttpRequest.new('http://localhost:9901')
      r1 = conn.aget :query => {:delay => 0.3}, :keepalive => true
      r2 = conn.aget :query => {:delay => 0.2}

      r1.errback { fail }
      r1.callback do |c|
        res << c.response
        expect(c.response).to match('0.3')
      end

      r2.errback { fail }
      r2.callback do |c|
        res << c.response

        expect(res).to eq(['0.3', '0.2'])
        expect(Time.now.to_f - start).to be_within(0.1).of(0.3)

        stop
      end
    end
  end
end
