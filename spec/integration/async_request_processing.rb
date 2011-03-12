require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/async_upload')

describe 'Async Request processing' do
  it 'asynchronously processes the incoming request' do
    with_api(AsyncUpload) do
      request_data = {
        :body => {:some => :data},
        :head => {'X-Upload' => 'custom'}
      }

      err = Proc.new { fail "API request failed" }

      post_request(request_data, err) do |c|
        resp = Yajl::Parser.parse(c.response)
        resp['body'].should match('some=data')
        resp['head'].should include('X-Upload')
      end
    end
  end
end
