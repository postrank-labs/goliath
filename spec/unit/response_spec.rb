require 'spec_helper'
require 'goliath/response'

describe Goliath::Response do
  before(:each) do
    @r = Goliath::Response.new
  end

  it 'allows setting status' do
    @r.status = 400
    expect(@r.status).to eq(400)
  end

  it 'allows setting headers' do
    @r.headers = [['my_key', 'my_headers']]
    expect(@r.headers.to_s).to eq("my_key: my_headers\r\n")
  end

  it 'allows setting body' do
    @r.body = 'my body'
    expect(@r.body).to eq('my body')
  end

  it 'sets a default status' do
    expect(@r.status).to eq(200)
  end

  it 'sets default headers' do
    expect(@r.headers).not_to be_nil
  end

  it 'outputs the http header' do
    expect(@r.head).to eq("HTTP/1.1 200 OK\r\n")
  end
end