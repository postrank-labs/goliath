require 'spec_helper'

require 'em-synchrony'
require 'em-synchrony/em-http'

require 'rack'
require 'goliath/server'

require File.join(File.dirname(__FILE__), '../../', 'examples/echo')

describe Echo do
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

  it 'returns the echo param' do
    EM.synchrony do
      server

      req = EM::HttpRequest.new('http://localhost:9000').get :query => {:echo => 'test'}
      req.callback do |c|
        b = JSON.parse(c.response)
        b['response'].should == 'test'
        EM.stop
      end
      req.errback do |c|
        fail 'HTTP request failed'
        EM.stop
      end
    end
  end

  it 'returns error without echo' do
    EM.synchrony do
      server

      req = EM::HttpRequest.new('http://localhost:9000').get
      req.callback do |c|
        b = JSON.parse(c.response)
        b['error'].should_not be_nil
        b['error'].should == 'Echo identifier missing'
        EM.stop
      end
      req.errback do |c|
        fail 'HTTP request failed'
        EM.stop
      end
    end
  end
end
