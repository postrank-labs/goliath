require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/echo')

describe 'HTTP Keep-Alive support' do
  it 'serves multiple requests via single connection' do
    with_api(Echo) do
      conn = EM::HttpRequest.new('http://localhost:9000')
      r1 = conn.get(:query => {:echo => 'test'}, :keepalive => true)

      r1.errback { fail }
      r1.callback do |c|
        b = Yajl::Parser.parse(c.response)
        b['response'].should == 'test'

        r2 = conn.get(:query => {:echo => 'test2'})
        r2.errback { fail }
        r2.callback do |c|
          b = Yajl::Parser.parse(c.response)
          b['response'].should == 'test2'

          stop
        end
      end
    end
  end
end
