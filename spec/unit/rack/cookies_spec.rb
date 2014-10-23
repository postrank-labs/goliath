require 'spec_helper'
require 'goliath/rack/cookies'
require 'goliath/env'

describe Goliath::Rack::Cookies do
  it 'accepts an app' do
    expect { Goliath::Rack::Cookies.new('my app') }.to_not raise_error
  end

  describe 'with the middleware' do
    let(:app) { double('app', call: [200, {}, []]).as_null_object }
    let(:env) { Goliath::Env.new }
    let(:cookies) { Goliath::Rack::Cookies.new(app) }

    let(:response) { cookies.call(env) }

    describe 'the environment' do
      let(:expectations) {  }

      subject { env }

      before do
        expectations

        response
      end

      it { is_expected.to include('rack.cookies') }

      describe 'rack.cookies' do
        subject { env['rack.cookies'] }

        it { is_expected.to be_empty }

        context 'with the HTTP_COOKIE header present' do
          let(:env) { Goliath::Env.new.merge('HTTP_COOKIE' =>  'name=value') }

          it { is_expected.to eq('name' => 'value') }
        end

        context 'with a cookie set from the app' do
          let(:expectations) do
            allow(app).to receive(:call) do |env|
              env['rack.cookies']['name'] = 'value'

              [200, {}, []]
            end
          end

          it { is_expected.to eq('name' => 'value') }
        end
      end
    end

    describe 'the headers' do
      subject { response[1] }

      it { is_expected.to be_an_instance_of(Rack::Utils::HeaderHash) }
      it { is_expected.to be_a_kind_of(Hash) }
      it { is_expected.to be_empty }

      context 'with the HTTP_COOKIE header present' do
        let(:env) { Goliath::Env.new.merge('HTTP_COOKIE' =>  'name=value') }

        it { is_expected.to be_empty }
      end

      context 'with a cookie set from the app' do
        before do
          allow(app).to receive(:call) do |env|
            env['rack.cookies']['name'] = 'value'

            [200, {}, []]
          end
        end

        it { is_expected.to eq('Set-Cookie' => 'name=value; path=/') }
      end

      context 'with a cookie deleted by the app' do
        let(:env) { Goliath::Env.new.merge('HTTP_COOKIE' =>  'name=value') }
        let(:delete_header) {
          { 'Set-Cookie' => 'name=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000' }
        }

        before do
          allow(app).to receive(:call) do |env|
            expect(env['rack.cookies']).to eq('name' => 'value')

            env['rack.cookies'].delete('name')

            [200, {}, []]
          end
        end

        it { is_expected.to eq(delete_header) }
      end
    end
  end
end
