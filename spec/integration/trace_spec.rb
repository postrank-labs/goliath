require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/echo')


describe Goliath::Rack::Tracer do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'injects a trace param on a 200 (via async callback)' do
    with_api(Echo) do
      get_request({:query => {:echo => 'test'}}, err) do |c|
        expect(c.response_header['X_POSTRANK']).to match(/trace\.start: [\d\.]+, total: [\d\.]+/)
      end
    end
  end

  it 'injects a trace param on a 400 (direct callback)' do
    with_api(Echo) do
      get_request({}, err) do |c|
        expect(c.response_header['X_POSTRANK']).to match(/trace\.start: [\d\.]+, total: [\d\.]+/)
      end
    end
  end
end
