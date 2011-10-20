require 'spec_helper'
require 'goliath/rack/render'
require 'goliath/goliath'

describe Goliath::Rack::Render do
  let(:env) do
    env = Goliath::Env.new
    env['params'] = {}
    env
  end

  let(:app) { mock('app').as_null_object }
  let(:render) { Goliath::Rack::Render.new(app) }

  it 'accepts an app' do
    lambda { Goliath::Rack::Render.new('my app') }.should_not raise_error
  end

  it 'returns the status, body and app headers' do
    app_body = {'c' => 'd'}

    app.should_receive(:call).and_return([200, {'a' => 'b'}, app_body])
    status, headers, body = render.call(env)

    status.should == 200
    headers['a'].should == 'b'
    body.should == app_body
  end

  describe 'Vary' do
    it 'adds Accept to provided Vary header' do
      app.should_receive(:call).and_return([200, {'Vary' => 'Cookie'}, {}])
      status, headers, body = render.call(env)
      headers['Vary'].should == 'Cookie,Accept'
    end

    it 'sets Accept if there is no Vary header' do
      app.should_receive(:call).and_return([200, {}, {}])
      status, headers, body = render.call(env)
      headers['Vary'].should == 'Accept'
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
      app.should_receive(:call).and_return([200, {}, {}])
    end

    describe 'from header' do
      CONTENT_TYPES.values.each do |type|
        it "handles content type for #{type}" do
          env['HTTP_ACCEPT'] = type
          status, headers, body = render.call(env)
          headers['Content-Type'].should =~ /^#{Regexp.escape(type)}/
        end
      end
    end

    describe 'from URL param' do
      CONTENT_TYPES.each_pair do |format, content_type|
        it "converts #{format} to #{content_type}" do
          env['params']['format'] = format
          status, headers, body = render.call(env)
          headers['Content-Type'].should =~ /^#{Regexp.escape(content_type)}/
        end
      end
    end

    it 'prefers URL format over header' do
      env['HTTP_ACCEPT'] = 'application/xml'
      env['params']['format'] = 'json'
      status, headers, body = render.call(env)
      headers['Content-Type'].should =~ %r{^application/json}
    end

    describe 'charset' do
      it 'is set if not present' do
        env['params']['format'] = 'json'
        status, headers, body = render.call(env)
        headers['Content-Type'].should =~ /; charset=utf-8$/
      end
    end
  end
end
