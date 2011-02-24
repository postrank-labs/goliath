require 'spec_helper'

require 'em-synchrony'
require 'em-synchrony/em-http'

require 'rack'
require 'goliath/server'

require File.join(File.dirname(__FILE__), '../../', 'examples/echo')

describe 'HTTP Keep-Alive support' do
  let(:app) do
    ::Rack::Builder.new do
      Echo.middlewares.each do |mw|
        use(*(mw[0..1].compact), &mw[2])
      end
      run Echo.new
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

      conn = EM::HttpRequest.new('http://localhost:9000')
      r1 = conn.get :query => {:echo => 'test'}, :keepalive => true

      r1.errback { fail }
      r1.callback do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'

        r2 = conn.get :query => {:echo => 'test2'}
        r2.errback { fail }
        r2.callback do |c|
          b = Yajl::Parser.parse(c.response)
          b['response'].should == 'test2'

          EM.stop
        end
      end
    end
  end

end
