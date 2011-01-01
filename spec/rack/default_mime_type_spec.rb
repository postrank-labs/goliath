require 'spec_helper'
require 'api/v3/lib/goliath/env'
require 'api/v3/lib/goliath/rack/default_mime_type'

describe Goliath::Rack::DefaultMimeType do
  let(:app) { mock('app').as_null_object }
  let(:dmt) { Goliath::Rack::DefaultMimeType.new(app) }
  let(:env) do
    env = Goliath::Env.new
    env['status'] = mock('status').as_null_object
    env
  end

  context 'accept header cleanup' do
    %w(gzip deflate compressed identity).each do |type|
      it "removes #{type} from the accept header" do
        env['HTTP_ACCEPT'] = "text/html, #{type}, text/javascript"
        dmt.call(env)
        env['HTTP_ACCEPT'].should == 'text/html, text/javascript'
      end
    end

    it 'sets to */* if all entries removed' do
      env['HTTP_ACCEPT'] = 'identity'
      dmt.call(env)
      env['HTTP_ACCEPT'].should == '*/*'
    end
  end
end