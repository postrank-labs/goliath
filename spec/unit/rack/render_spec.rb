require 'spec_helper'
require 'goliath/rack/render'
require 'goliath/goliath'

describe Goliath::Rack::Render do
  let(:env) do
    env = Goliath::Env.new
    env['params'] = {}
    env
  end

  let(:app) { double('app').as_null_object }
  let(:render) { Goliath::Rack::Render.new(app) }

  it 'accepts an app' do
    expect { Goliath::Rack::Render.new('my app') }.not_to raise_error
  end

  it 'returns the status, body and app headers' do
    app_body = {'c' => 'd'}

    expect(app).to receive(:call).and_return([200, {'a' => 'b'}, app_body])
    status, headers, body = render.call(env)

    expect(status).to eq(200)
    expect(headers['a']).to eq('b')
    expect(body).to eq(app_body)
  end

  describe 'Vary' do
    it 'adds Accept to provided Vary header' do
      expect(app).to receive(:call).and_return([200, {'Vary' => 'Cookie'}, {}])
      status, headers, body = render.call(env)
      expect(headers['Vary']).to eq('Cookie,Accept')
    end

    it 'sets Accept if there is no Vary header' do
      expect(app).to receive(:call).and_return([200, {}, {}])
      status, headers, body = render.call(env)
      expect(headers['Vary']).to eq('Accept')
    end
  end

  CONTENT_TYPES = {
    'rss' => 'application/rss+xml',
    'xml' => 'application/xml',
    'html' => 'text/html',
    'json' => 'application/json',
    'yaml' => 'text/yaml',
  }

  describe 'Content-Type' do
    before(:each) do
      expect(app).to receive(:call).and_return([200, {}, {}])
    end

    describe 'from header' do
      CONTENT_TYPES.values.each do |type|
        it "handles content type for #{type}" do
          env['HTTP_ACCEPT'] = type
          status, headers, body = render.call(env)
          expect(headers['Content-Type']).to match(/^#{Regexp.escape(type)}/)
        end
      end
    end

    describe 'from URL param' do
      CONTENT_TYPES.each_pair do |format, content_type|
        it "converts #{format} to #{content_type}" do
          env['params']['format'] = format
          status, headers, body = render.call(env)
          expect(headers['Content-Type']).to match(/^#{Regexp.escape(content_type)}/)
        end
      end
    end

    it 'prefers URL format over header' do
      env['HTTP_ACCEPT'] = 'application/xml'
      env['params']['format'] = 'json'
      status, headers, body = render.call(env)
      expect(headers['Content-Type']).to match(%r{^application/json})
    end

    describe 'charset' do
      it 'is set if not present' do
        env['params']['format'] = 'json'
        status, headers, body = render.call(env)
        expect(headers['Content-Type']).to match(/; charset=utf-8$/)
      end
    end
  end
end
