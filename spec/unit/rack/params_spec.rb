require 'spec_helper'
require 'goliath/rack/params'

describe Goliath::Rack::Params do
  it 'accepts an app' do
    lambda { Goliath::Rack::Params.new('my app') }.should_not raise_error
  end

  describe 'with middleware' do
    before(:each) do
      @app = mock('app').as_null_object
      @env = {}
      @env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded; charset=utf-8'
      @params = Goliath::Rack::Params.new(@app)
    end

    it 'parses the query string' do
      @env['QUERY_STRING'] = 'foo=bar&baz=bonkey'

      ret = @params.retrieve_params(@env)
      ret['foo'].should == 'bar'
      ret['baz'].should == 'bonkey'
    end

    it 'parses the nested query string' do
      @env['QUERY_STRING'] = 'foo[bar]=baz'

      ret = @params.retrieve_params(@env)
      ret['foo'].should == {'bar' => 'baz'}
    end

    it 'parses the post body' do
      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foo=bar&baz=bonkey&zonk[donk]=monk"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      ret['foo'].should == 'bar'
      ret['baz'].should == 'bonkey'
      ret['zonk'].should == {'donk' => 'monk'}
    end

    it 'parses arrays of data' do
      @env['QUERY_STRING'] = 'foo[]=bar&foo[]=baz&foo[]=foos'

      ret = @params.retrieve_params(@env)
      ret['foo'].is_a?(Array).should be_true
      ret['foo'].length.should == 3
      ret['foo'].should == %w(bar baz foos)
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
      ret['submit-name'].should == 'Larry'
      ret['submit-name-with-content'].should == 'Berry'
    end

    it 'combines query string and post body params' do
      @env['QUERY_STRING'] = "baz=bar"

      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foos=bonkey"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      ret['baz'].should == 'bar'
      ret['foos'].should == 'bonkey'
    end

    it 'handles empty query and post body' do
      ret = @params.retrieve_params(@env)
      ret.is_a?(Hash).should be_true
      ret.should be_empty
    end

    it 'prefers post body over query string' do
      @env['QUERY_STRING'] = "foo=bar1&baz=bar"

      @env['rack.input'] = StringIO.new
      @env['rack.input'] << "foo=bar2&baz=bonkey"
      @env['rack.input'].rewind

      ret = @params.retrieve_params(@env)
      ret['foo'].should == 'bar2'
      ret['baz'].should == 'bonkey'
    end

    it 'sets the params into the environment' do
      @app.should_receive(:call).with do |app_env|
        app_env.has_key?('params').should be_true
        app_env['params']['a'].should == 'b'
      end

      @env['QUERY_STRING'] = "a=b"
      @params.call(@env)
    end

    it 'returns status, headers and body from the app' do
      app_headers = {'Content-Type' => 'hash'}
      app_body = {:a => 1, :b => 2}
      @app.should_receive(:call).and_return([200, app_headers, app_body])

      status, headers, body = @params.call(@env)
      status.should == 200
      headers.should == app_headers
      body.should == app_body
    end

    context 'content type' do
      it "parses application/x-www-form-urlencoded" do
        @env['CONTENT_TYPE'] = 'application/x-www-form-urlencoded; charset=utf-8'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << "foos=bonkey"
        @env['rack.input'].rewind

        ret = @params.retrieve_params(@env)
        ret['foos'].should == 'bonkey'
      end

      it "parses json" do
        @env['CONTENT_TYPE'] = 'application/json'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << %|{"foo":"bar"}|
        @env['rack.input'].rewind

        ret = @params.retrieve_params(@env)
        ret['foo'].should == 'bar'
      end

      it "handles empty input gracefully on JSON" do
        @env['CONTENT_TYPE'] = 'application/json'
        @env['rack.input'] = StringIO.new

        ret = @params.retrieve_params(@env)
        ret.should be_empty
      end

      it "raises a BadRequestError on invalid JSON" do
        @env['CONTENT_TYPE'] = 'application/json'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << %|{"foo":"bar" BORKEN}|
        @env['rack.input'].rewind

        lambda{ @params.retrieve_params(@env) }.should raise_error(Goliath::Validation::BadRequestError)
      end

      it "doesn't parse unknown content types" do
        @env['CONTENT_TYPE'] = 'fake/form -- type'
        @env['rack.input'] = StringIO.new
        @env['rack.input'] << %|{"foo":"bar"}|
        @env['rack.input'].rewind

        ret = @params.retrieve_params(@env)
        ret.should == {}
      end
    end
  end
end
