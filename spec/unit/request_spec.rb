require 'spec_helper'

describe Goliath::Request do
  before(:each) do
    app = double('app').as_null_object
    env = Goliath::Env.new

    @r = Goliath::Request.new(app, nil, env)
  end

  describe 'initialization' do
    it 'initializes env defaults' do
      env = Goliath::Env.new
      env['INIT'] = 'init'

      r = Goliath::Request.new(nil, nil, env)
      expect(r.env['INIT']).to eq('init')
    end

    it 'initializes an async callback' do
      expect(@r.env['async.callback']).not_to be_nil
    end

    it 'initializes request' do
      expect(@r.instance_variable_get("@state")).to eq(:processing)
    end
  end

  describe 'process' do
    it 'executes the application' do
      app_mock = double('app').as_null_object
      env_mock = double('app').as_null_object
      request = Goliath::Request.new(app_mock, nil, env_mock)

      expect(app_mock).to receive(:call).with(request.env)
      expect(request).to receive(:post_process)

      request.process
    end
  end

  describe 'finished?' do
    it "returns false if the request parsing has not yet finished" do
      expect(@r.finished?).to be false
    end

    it 'returns true if we have finished request parsing' do
      expect(@r).to receive(:post_process).and_return(nil)
      @r.process

      expect(@r.finished?).to be true
    end
  end

  describe 'parse_headers' do
    it 'sets content_type correctly' do
      parser = double('parser').as_null_object
      allow(parser).to receive(:request_url).and_return('')

      @r.parse_header({'Content-Type' => 'text/plain'}, parser)
      expect(@r.env['CONTENT_TYPE']).to eq('text/plain')
    end

    it 'handles bad request urls' do
      parser = double('parser').as_null_object
      allow(parser).to receive(:request_url).and_return('/bad?params##')

      allow(@r).to receive(:server_exception)
      expect(@r).to receive(:server_exception)
      @r.parse_header({}, parser)
    end

    it 'sets content_length correctly' do
      parser = double('parser').as_null_object
      allow(parser).to receive(:request_url).and_return('')

      @r.parse_header({'Content-Length' => 42}, parser)
      expect(@r.env['CONTENT_LENGTH']).to eq(42)
    end

    it 'sets server_name and server_port correctly' do
      parser = double('parser').as_null_object
      allow(parser).to receive(:request_url).and_return('')

      @r.parse_header({'Host' => 'myhost.com:3000'}, parser)
      expect(@r.env['SERVER_NAME']).to eq('myhost.com')
      expect(@r.env['SERVER_PORT']).to eq('3000')
    end
  end
end
