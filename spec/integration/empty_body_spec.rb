require 'spec_helper'

class Empty < Goliath::API
  def response(env)
    [201, {}, []]
  end
end

describe 'Empty body API' do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'serves a 201 with no body' do
    with_api(Empty) do
      get_request({}, err) do |c|
        expect(c.response_header.status).to eq(201)
        expect(c.response_header['CONTENT_LENGTH']).to eq('0')
      end
    end
  end
end
