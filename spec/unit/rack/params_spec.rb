require 'spec_helper'
require 'goliath/rack/params'

describe Goliath::Rack::Params do
  it 'accepts an app' do
    expect { Goliath::Rack::Params.new('my app') }.not_to raise_error
  end

  describe 'with middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @env = {}
      @env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded; charset=utf-8'
      @params = Goliath::Rack::Params.new(@app)
    end

    it 'handles invalid query strings' do
      @env['QUERY_STRING'] = 'bad=%3N'
      expect {
        @params.retrieve_params(@env)
      }.to raise_error(Goliath::Validation::BadRequestError)
    end

    it 'handles ambiguous query strings' do
      @env['QUERY_STRING'] = 'ambiguous[]=&ambiguous[4]='
      expect {
        @params.retrieve_params(@env)
      }.to raise_error(Goliath::Validation::Error)
    end

    it 'parses the query string' do
      @env['QUERY_STRING'] = 'foo=bar&baz=bonkey'

      ret = @params.retrieve_params(@env)
      expect(ret['foo']).to eq('bar')
      expect(ret['baz']).to eq('bonkey')
    end

    it 'parses the nested query string' do
      @env['QUERY_STRING'] = 'foo[bar]=baz'

      ret = @params.retrieve_params(@env)
      expect(ret['foo']).to eq({'bar' => 'baz'})
    end

    it 'parses the post body' do
      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foo=bar&baz=bonkey&zonk[donk]=monk"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      expect(ret['foo']).to eq('bar')
      expect(ret['baz']).to eq('bonkey')
      expect(ret['zonk']).to eq({'donk' => 'monk'})
    end

    it 'parses arrays of data' do
      @env['QUERY_STRING'] = 'foo[]=bar&foo[]=baz&foo[]=foos'

      ret = @params.retrieve_params(@env)
      expect(ret['foo'].is_a?(Array)).to be true
      expect(ret['foo'].length).to eq(3)
      expect(ret['foo']).to eq(%w(bar baz foos))
    end

    it 'parses multipart data' do
      @env[Goliath::Constants::CONTENT_TYPE] = 'multipart/boundary="AaB03x"'
      @env['rack.input'] = StringIO.new
      @env['rack.input'] <<"--AaB03x\r
Content-Disposition: form-data; name=\"submit-name\"\r
\r
Larry\r
--AaB03x\r
Content-Disposition: form-data; name=\"submit-name-with-content\"\r
\r
Berry\r
--AaB03x--\r
"

      @env[Goliath::Constants::CONTENT_LENGTH] = @env['rack.input'].length

      ret = @params.retrieve_params(@env)
      expect(ret['submit-name']).to eq('Larry')
      expect(ret['submit-name-with-content']).to eq('Berry')
    end

    it 'combines query string and post body params' do
      @env['QUERY_STRING'] = "baz=bar"

      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foos=bonkey"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      expect(ret['baz']).to eq('bar')
      expect(ret['foos']).to eq('bonkey')
    end

    it 'handles empty query and post body' do
      ret = @params.retrieve_params(@env)
      expect(ret.is_a?(Hash)).to be true
      expect(ret).to be_empty
    end

    it 'prefers post body over query string' do
      @env['QUERY_STRING'] = "foo=bar1&baz=bar"

      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foo=bar2&baz=bonkey"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      expect(ret['foo']).to eq('bar2')
      expect(ret['baz']).to eq('bonkey')
    end

    it 'sets the params into the environment' do
      expect(@app).to receive(:call).with(hash_including("params"=>{"a"=>"b"}))

      @env['QUERY_STRING'] = "a=b"
      @params.call(@env)
    end

    it 'returns status, headers and body from the app' do
      app_headers = {'Content-Type' => 'hash'}
      app_body = {:a => 1, :b => 2}
      expect(@app).to receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @params.call(@env)
      expect(status).to eq(200)
      expect(headers).to eq(app_headers)
      expect(body).to eq(app_body)
    end

    it 'returns a validation error if one is raised while parsing' do
      expect(@app).to_not receive(:call)
      params_exception = Goliath::Validation::Error.new(423, 'invalid')
      expect(@params).to receive(:retrieve_params).and_raise(params_exception)
      status, headers, body = @params.call(@env)
      expect(status).to eq 423
      expect(headers).to eq({})
      expect(body).to eq(error: 'invalid')
    end

    it 'returns a 500 error if an unexpected error is raised while parsing' do
      expect(@app).to_not receive(:call)

      params_exception = Exception.new('uh oh')
      expect(@params).to receive(:retrieve_params).and_raise(params_exception)

      logger = double('logger').as_null_object
      expect(@env).to receive(:logger).twice.and_return(logger)

      status, headers, body = @params.call(@env)
      expect(status).to eq 500
      expect(headers).to eq({})
      expect(body).to eq(error: 'uh oh')
    end

    it 'does not swallow exceptions from the app' do
      app_exception = Class.new(Exception)
      expect(@app).to receive(:call).and_raise(app_exception)
      expect { @params.call(@env) }.to raise_error(app_exception)
    end

    context 'content type' do
      it "parses application/x-www-form-urlencoded" do
        @env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded; charset=utf-8'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << "foos=bonkey"
        @env['rack.input'].rewind

        ret = @params.retrieve_params(@env)
        expect(ret['foos']).to eq('bonkey')
      end

      ['application/json', 'application/vnd.api+json', 'application/javascript'].each do |content_type|
        it "parses #{content_type}" do
          @env['CONTENT_TYPE'] = content_type
          @env['rack.input'] = StringIO.new
          @env['rack.input'] << %|{"foo":"bar"}|
          @env['rack.input'].rewind

          ret = @params.retrieve_params(@env)
          expect(ret['foo']).to eq('bar')
        end

        it "parses #{content_type} that does not evaluate to a hash" do
          @env['CONTENT_TYPE'] = content_type
          @env['rack.input'] = StringIO.new
          @env['rack.input'] << %|["foo","bar"]|
          @env['rack.input'].rewind

          ret = @params.retrieve_params(@env)
          expect(ret['_json']).to eq(['foo', 'bar'])
        end

        it "handles empty input gracefully on #{content_type} JSON" do
          @env['CONTENT_TYPE'] = content_type
          @env['rack.input'] = StringIO.new

          ret = @params.retrieve_params(@env)
          expect(ret).to be_empty
        end

        it "raises a BadRequestError on invalid #{content_type} JSON" do
          @env['CONTENT_TYPE'] = content_type
          @env['rack.input'] = StringIO.new
          @env['rack.input'] << %|{"foo":"bar" BORKEN}|
          @env['rack.input'].rewind

          expect{ @params.retrieve_params(@env) }.to raise_error(Goliath::Validation::BadRequestError)
        end
      end

      it "doesn't parse unknown content types" do
        @env['CONTENT_TYPE'] = 'fake/form -- type'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << %|{"foo":"bar"}|
        @env['rack.input'].rewind

        ret = @params.retrieve_params(@env)
        expect(ret).to eq({})
      end
    end
  end
end
