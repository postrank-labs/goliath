require 'spec_helper'

class Empty < Goliath::API
  def response(env)
    [201, {}, []]
  end
end

describe 'Empty body API' do
  it 'serves a 201 with no body' do
    with_api(Empty) do
      http = EM::HttpRequest.new('http://localhost:9000').get
      http.errback { fail }
      http.callback do |c|
        c.response_header.status.should == 201
        c.response_header['CONTENT_LENGTH'].should == '0'
        stop
      end
    end
  end
end
