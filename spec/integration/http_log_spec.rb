require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'examples/http_log')

class Responder < Goliath::API
  use Goliath::Rack::Params

  def on_headers(env, headers)
    env['client-headers'] = headers
  end

  def response(env)
    query_params = env.params.collect { |param| param.join(": ") }
    query_headers = env['client-headers'].collect { |param| param.join(": ") }

    headers = {"Special" => "Header",
               "Params" => query_params.join("|"),
               "Path" => env[Goliath::Request::REQUEST_PATH],
               "Headers" => query_headers.join("|"),
               "Method" => env[Goliath::Request::REQUEST_METHOD]}
    [200, headers, "Hello from Responder"]
  end
end

describe HttpLog do
  include Goliath::TestHelper

  let(:err) { Proc.new { |c| fail "HTTP Request failed #{c.response}" } }

  def config_file
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'examples', 'config', 'http_log.rb'))
  end

  let(:api_options) { { :config => config_file } }

  def mock_mongo(api)
    api.config['mongo'] = double('mongo').as_null_object
  end

  it 'responds to requests' do
    with_api(HttpLog, api_options) do |api|
      server(Responder, 8080)
      mock_mongo(api)

      get_request({}, err) do |c|
        expect(c.response_header.status).to eq(200)
      end
    end
  end

  it 'forwards to our API server' do
    with_api(HttpLog, api_options) do |api|
      server(Responder, 8080)
      mock_mongo(api)

      get_request({}, err) do |c|
        expect(c.response_header.status).to eq(200)
        expect(c.response_header['SPECIAL']).to eq('Header')
        expect(c.response).to eq('Hello from Responder')
      end
    end
  end

  context 'HTTP header handling' do
    it 'transforms back properly' do
      hl = HttpLog.new
      expect(hl.to_http_header("SPECIAL")).to eq('Special')
      expect(hl.to_http_header("CONTENT_TYPE")).to eq('Content-Type')
    end
  end

  context 'query parameters' do
    it 'forwards the query parameters' do
      with_api(HttpLog, api_options) do |api|
        server(Responder, 8080)
        mock_mongo(api)

        get_request({:query => {:first => :foo, :second => :bar, :third => :baz}}, err) do |c|
          expect(c.response_header.status).to eq(200)
          expect(c.response_header["PARAMS"]).to eq("first: foo|second: bar|third: baz")
        end
      end
    end
  end

  context 'request path' do
    it 'forwards the request path' do
      with_api(HttpLog, api_options) do |api|
        server(Responder, 8080)
        mock_mongo(api)

        get_request({:path => '/my/request/path'}, err) do |c|
          expect(c.response_header.status).to eq(200)
          expect(c.response_header['PATH']).to eq('/my/request/path')
        end
      end
    end
  end

  context 'headers' do
    it 'forwards the headers' do
      with_api(HttpLog, api_options) do |api|
        server(Responder, 8080)
        mock_mongo(api)

        get_request({:head => {:first => :foo, :second => :bar}}, err) do |c|
          expect(c.response_header.status).to eq(200)
          expect(c.response_header["HEADERS"]).to match(/First: foo\|Second: bar/)
        end
      end
    end
  end

  context 'request method' do
    it 'forwards GET requests' do
      with_api(HttpLog, api_options) do |api|
        server(Responder, 8080)
        mock_mongo(api)

        get_request({}, err) do |c|
          expect(c.response_header.status).to eq(200)
          expect(c.response_header["METHOD"]).to eq("GET")
        end
      end
    end

    it 'forwards POST requests' do
      with_api(HttpLog, api_options) do |api|
        server(Responder, 8080)
        mock_mongo(api)

        post_request({}, err) do |c|
          expect(c.response_header.status).to eq(200)
          expect(c.response_header["METHOD"]).to eq("POST")
        end
      end
    end
  end
end
