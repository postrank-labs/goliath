require 'spec_helper'

require 'em-synchrony'
require 'em-synchrony/em-http'

require 'rack'
require 'goliath'
require 'yajl'

require File.join(File.dirname(__FILE__), '../../', 'examples/async_upload')


describe 'Async Request processing' do
  let(:api) { AsyncUpload }

  let(:app) do
    api_klass = api
    ::Rack::Builder.new do
      api_klass.middlewares.each do |mw|
        use(*(mw[0..1].compact), &mw[2])
      end
      run api_klass.new
    end
  end

  let(:server) do
    s = Goliath::Server.new
    s.logger = mock('log').as_null_object
    s.api = api.new
    s.app = app
    s.start
  end

  it 'asynchronously processes the incoming request' do
    EM.synchrony do
      server

      req = EM::HttpRequest.new('http://localhost:9000').post({
        :body => {:some => :data},
        :head => {'X-Upload' => 'custom'}
      })

      req.errback  { fail }
      req.callback do |c|
        resp = Yajl::Parser.parse(c.response)
        resp['body'].should match('some=data')
        resp['head'].should include('X-Upload')

        EM.stop
      end

    end
  end

end
