require 'spec_helper'

class JSON_API < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::JSONP
  use Goliath::Rack::Render, 'json'

  def response(env)
    headers = {
      'CONTENT_TYPE' => 'application/json',
      # Note: specifically not 'CONTENT_LENGTH'. 'Content-Length' gets set by
      # AsyncRack::ContentLength if not already present. So if we set
      # 'CONTENT_LENGTH', no problem - AsyncRack recalculates the body's
      # content length anyway and stores it in the 'Content-Length' header. But
      # if we set 'Content-Length', AsyncRack will avoid overwriting it. We
      # thus want the JSONP middleware to react to the case where we've
      # *already* set the 'Content-Length' header before hitting it.
      'Content-Length' => '2',
    }
    [200, headers, 'OK']
  end
end

describe 'JSONP' do
  let(:err) { Proc.new { fail "API request failed" } }

  context 'without a callback param' do
    let(:query) { {} }

    it 'does not alter the content type' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response_header['CONTENT_TYPE']).to match(%r{^application/json})
        end
      end
    end

    it 'does not alter the content length' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response_header['CONTENT_LENGTH'].to_i).to eq(2)
        end
      end
    end

    it 'does not wrap the response with anything' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response).to eq('OK')
        end
      end
    end
  end

  context 'with a callback param' do
    let(:query) { { callback: 'test' } }

    it 'adjusts the content type' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response_header['CONTENT_TYPE']).to match(%r{^application/javascript})
        end
      end
    end

    it 'adjusts the content length' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response_header['CONTENT_LENGTH'].to_i).to eq(8)
        end
      end
    end

    it 'wraps response with callback' do
      with_api(JSON_API) do
        get_request({ query: query }, err) do |c|
          expect(c.response).to match(/^test\(.*\)$/)
        end
      end
    end
  end
end
