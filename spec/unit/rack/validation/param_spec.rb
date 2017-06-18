require 'spec_helper'
require 'goliath/rack/validation/param'

describe Goliath::Rack::Validation::Param do
  before do
    @app = double('app').as_null_object
    @env = {'params' => {}}
  end

  it "should not allow invalid options" do
    expect {
      Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => Class.new})
    }.to raise_error(Exception)
  end

  it "raises if key is not supplied" do
    expect {
      Goliath::Rack::Validation::Param.new(@app)
    }.to raise_error(Exception)
  end

  it "uses a default value if optional is not supplied" do
    cv = Goliath::Rack::Validation::Param.new(@app, :key => 'key')
    expect(cv.optional).to be false
  end

  it "should have default and message be optional" do
    cv = nil
    expect {
      cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'flag',
          :as => Goliath::Rack::Types::Boolean})
    }.not_to raise_error

    expect(cv.default).to be_nil
    expect(cv.message).not_to be_nil
  end

  it "should fail if given an invalid option" do
    cv = nil
    expect {
      cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'flag',
          :as => Goliath::Rack::Types::Boolean, :animal => :monkey})
    }.to raise_error('Unknown options: {:animal=>:monkey}')
  end

  context "fetch_key" do
    before do
      @cv = Goliath::Rack::Validation::Param.new(@app,
          :key => ['data', 'credentials', 'login'])
    end

    it "should return a valid value given the correct params" do
      params = {
        'data' => {
          'credentials' => {
            'login' => "mike"
          }
        }
      }
      expect(@cv.fetch_key(params)).to eq("mike")
    end

    it "should return nil given an incorrect params" do
      params = {
        'data' => {
          'credentials' => {
            'login2' => "mike"
          }
        }
      }
      expect(@cv.fetch_key(params)).to be_nil
    end

    it "should set value if given" do
      params = {
        'data' => {
          'credentials' => {
            'login' => "mike"
          }
        }
      }
      expect(@cv.fetch_key(params, "tim")).to eq("tim")
      expect(params['data']['credentials']['login']).to eq("tim")
    end
  end

  context "Required" do

    it 'defaults type and message' do
      @rp = Goliath::Rack::Validation::Param.new('app', :key => 'key')
      expect(@rp.type).not_to be_nil
      expect(@rp.type).not_to match(/^\s*$/)
      expect(@rp.message).to eq('identifier missing')
    end


    context 'with middleware' do
      before(:each) do
        @app = double('app').as_null_object
        @env = {'params' => {}}
        @rp = Goliath::Rack::Validation::Param.new(@app, {:type => 'Monkey',
            :key => 'mk', :message => 'is required'})
      end

      it 'stores type and key options' do
        expect(@rp.type).to eq('Monkey')
        expect(@rp.key).to eq('mk')
      end

      it 'calls validation_error with a custom message' do
        expect(@rp).to receive(:validation_error).with(anything, 'Monkey is required')
        @rp.call(@env)
      end

      it 'returns the app status, headers and body' do
        app_headers = {'Content-Type' => 'app'}
        app_body = {'b' => 'c'}
        expect(@app).to receive(:call).and_return([201, app_headers, app_body])

        @env['params']['mk'] = 'monkey'

        status, headers, body = @rp.call(@env)
        expect(status).to eq(201)
        expect(headers).to eq(app_headers)
        expect(body).to eq(app_body)
      end

      context 'key_valid?' do
        it 'raises exception if the key is not provided' do
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it 'raises exception if the key is blank' do
          @env['params']['mk'] = ''
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it 'raises exception if the key is nil' do
          @env['params']['mk'] = nil
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it 'handles an empty array' do
          @env['params']['mk'] = []
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it 'handles an array of nils' do
          @env['params']['mk'] = [nil, nil, nil]
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it 'handles an array of blanks' do
          @env['params']['mk'] = ['', '', '']
          expect(@rp.key_valid?(@env['params'])).to be false
        end

        it "doesn't raise if the key provided" do
          @env['params']['mk'] = 'my value'
          expect(@rp.key_valid?(@env['params'])).to be true
        end

        it "doesn't raise if the array contains valid data" do
          @env['params']['mk'] = [1, 2, 3, 4]
          expect(@rp.key_valid?(@env['params'])).to be true
        end

        it "doesn't raise if the key provided is multiline and has blanks" do
          @env['params']['mk'] = "my\n  \nvalue"
          expect(@rp.key_valid?(@env['params'])).to be true
        end

        it "doesn't raise if the key provided is an array and contains multiline with blanks" do
          @env['params']['mk'] = ["my\n  \nvalue", "my\n  \nother\n  \nvalue"]
          expect(@rp.key_valid?(@env['params'])).to be true
        end
      end
    end

    context 'Nested keys tests' do
      before do
        @app = double('app').as_null_object
        @env = {'params' => {}}
        @rp = Goliath::Rack::Validation::Param.new(@app, :type => 'Monkey',
            :key => ['data', 'credentials', 'login'],
            :message => 'is required')
      end

      it "return false if key's missing" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login2' => "user",
          'pass' => "password"}
        }
        }

        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it "return true if key is present" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login' => "user",
          'pass' => "password"}
        }
        }

        expect(@rp.key_valid?(@env['params'])).to be true
      end
    end

    context 'Nested keys tests (with string)' do
      before do
        @app = double('app').as_null_object
        @env = {'params' => {}}
        @rp = Goliath::Rack::Validation::Param.new(@app, :type => 'Monkey',
            :key => 'data.credentials.login', :message => 'is required')
      end

      it "return false if key's missing" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login2' => "user",
          'pass' => "password"}
        }
        }

        expect(@rp.key_valid?(@env['params'])).to be false
      end

      it "return true if key is present" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login' => "user",
          'pass' => "password"}
        }
        }

        expect(@rp.key_valid?(@env['params'])).to be true
      end
    end

  end

  context "Coerce" do

    it "should only accept a class in the :as" do
      expect {
        Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => "not a class"})
      }.to raise_error('Params as must be a class')
    end

    context 'with middleware' do
      {
        Goliath::Rack::Types::Boolean => [['t', true], ['true', true], ['f', false],
                                           ['false', false], ['1', true],
                                           ['0', false], ['TRUE', true],  ['FALSE', false],
                                           ['T', true], ['F', false]
      ],
        Goliath::Rack::Types::Integer => [['24', 24]],
        Goliath::Rack::Types::Float => [['24.3', 24.3]],
        Goliath::Rack::Types::Symbol => [['hi', :hi]],
      }.each do |type, values|
        values.each do |value|
          it "should coerce #{type} from #{value.first} to #{value[1]}" do
            @env['params']['user'] = value.first
            cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => type})
            cv.call(@env)
            expect(@env['params']['user']).to eq(value[1])
          end
        end
      end

      {
        Goliath::Rack::Types::Boolean => ["235", "hi", "3"],
        Goliath::Rack::Types::Integer => ["hi", "false", "true"],
        Goliath::Rack::Types::Symbol => [nil],
        Goliath::Rack::Types::Float => [nil],
      }.each do |type, values|
        values.each do |value|
          it "should not coerce #{type} with #{value}" do
            @env['params']['user'] = value
            cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => type})
            result = cv.call(@env)
            expect(result).to be_an_instance_of(Array)
            expect(result.first).to eq(400)
            expect(result.last).to have_key(:error)
          end
        end
      end

      it "should not fail with a invalid input, given a default value" do
        cv = nil
        @env['params']['user'] = "boo"
        expect {
          cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user',
              :as => Goliath::Rack::Types::Boolean , :default => 'default'})
        }.not_to raise_error
          @env['params']['user'] = 'default'
      end

      it "should be able to take a custom fail message" do
        @env['params']['user'] = "boo"
        cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user',
            :as => Goliath::Rack::Types::Integer, :message => "custom message"})

        result = cv.call(@env)
        expect(result).to be_an_instance_of(Array)
        expect(result.first).to eq(400)
        expect(result.last).to have_key(:error)
        expect(result.last[:error]).to eq("custom message")
      end
    end

  end

  context "Integration" do
    it "should do required param + coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer
      @env['params']['login'] = "3"
      cv.call(@env)
      expect(@env['params']['login']).to eq(3)

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer
      result = cv.call(@env)
      expect(result).to be_an_instance_of(Array)
      expect(result.first).to eq(400)
      expect(result.last).to have_key(:error)
    end

    it "should do required param + coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :as => Goliath::Rack::Types::Integer
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      expect(@env['params']['login']['other']).to eq(3)

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :as => Goliath::Rack::Types::Integer
      result = cv.call(@env)
      expect(result).to be_an_instance_of(Array)
      expect(result.first).to eq(400)
      expect(result.last).to have_key(:error)
    end

    it "should do required param + not coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login"
      @env['params']['login'] = "3"
      cv.call(@env)
      expect(@env['params']['login']).to eq("3")

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login"
      result = cv.call(@env)
      expect(result).to be_an_instance_of(Array)
      expect(result.first).to eq(400)
      expect(result.last).to have_key(:error)
    end

    it "should do required param + not coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other']
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      expect(@env['params']['login']['other']).to eq("3")

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other"
      result = cv.call(@env)
      expect(result).to be_an_instance_of(Array)
      expect(result.first).to eq(400)
      expect(result.last).to have_key(:error)
    end

    it "should do optional param + coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer, :optional => true
      @env['params']['login'] = "3"
      cv.call(@env)
      expect(@env['params']['login']).to eq(3)

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer, :optional => true
      result = cv.call(@env)
      expect(result).not_to be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param + coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :as => Goliath::Rack::Types::Integer, :optional => true
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      expect(@env['params']['login']['other']).to eq(3)

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :as => Goliath::Rack::Types::Integer, :optional => true
      result = cv.call(@env)
      expect(result).not_to be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param and not coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :optional => true
      @env['params']['login'] = "3"
      cv.call(@env)
      expect(@env['params']['login']).to eq("3")

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :optional => true
      result = cv.call(@env)
      expect(result).not_to be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param and not coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :optional => true
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      expect(@env['params']['login']['other']).to eq("3")

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :optional => true
      result = cv.call(@env)
      expect(result).not_to be_an_instance_of(Array) #implying its OK
    end
  end
end

