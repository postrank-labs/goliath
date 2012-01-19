require 'spec_helper'
require 'goliath/rack/validation/param'

describe Goliath::Rack::Validation::Param do
  before do
    @app = mock('app').as_null_object
    @env = {'params' => {}}
  end

  it "should not allow invalid options" do
    lambda {
      Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => Class.new})
    }.should raise_error
  end

  it "raises if key is not supplied" do
    lambda {
      Goliath::Rack::Validation::Param.new(@app)
    }.should raise_error(Exception)
  end

  it "uses a default value if optional is not supplied" do
    cv = Goliath::Rack::Validation::Param.new(@app, :key => 'key')
    cv.optional.should be_false
  end

  it "should have default and message be optional" do
    cv = nil
    lambda {
      cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'flag',
          :as => Goliath::Rack::Types::Boolean})
    }.should_not raise_error

    cv.default.should be_nil
    cv.message.should_not be_nil
  end

  it "should fail if given an invalid option" do
    cv = nil
    lambda {
      cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'flag',
          :as => Goliath::Rack::Types::Boolean, :animal => :monkey})
    }.should raise_error
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
      @cv.fetch_key(params).should == "mike"
    end

    it "should return nil given an incorrect params" do
      params = {
        'data' => {
          'credentials' => {
            'login2' => "mike"
          }
        }
      }
      @cv.fetch_key(params).should be_nil
    end

    it "should set value if given" do
      params = {
        'data' => {
          'credentials' => {
            'login' => "mike"
          }
        }
      }
      @cv.fetch_key(params, "tim").should == "tim"
      params['data']['credentials']['login'].should == "tim"
    end
  end

  context "Required" do

    it 'defaults type and message' do
      @rp = Goliath::Rack::Validation::Param.new('app', :key => 'key')
      @rp.type.should_not be_nil
      @rp.type.should_not =~ /^\s*$/
      @rp.message.should == 'identifier missing'
    end


    context 'with middleware' do
      before(:each) do
        @app = mock('app').as_null_object
        @env = {'params' => {}}
        @rp = Goliath::Rack::Validation::Param.new(@app, {:type => 'Monkey',
            :key => 'mk', :message => 'is required'})
      end

      it 'stores type and key options' do
        @rp.type.should == 'Monkey'
        @rp.key.should == 'mk'
      end

      it 'calls validation_error with a custom message' do
        @rp.should_receive(:validation_error).with(anything, 'Monkey is required')
        @rp.call(@env)
      end

      it 'returns the app status, headers and body' do
        app_headers = {'Content-Type' => 'app'}
        app_body = {'b' => 'c'}
        @app.should_receive(:call).and_return([201, app_headers, app_body])

        @env['params']['mk'] = 'monkey'

        status, headers, body = @rp.call(@env)
        status.should == 201
        headers.should == app_headers
        body.should == app_body
      end

      context 'key_valid?' do
        it 'raises exception if the key is not provided' do
          @rp.key_valid?(@env['params']).should be_false
        end

        it 'raises exception if the key is blank' do
          @env['params']['mk'] = ''
          @rp.key_valid?(@env['params']).should be_false
        end

        it 'raises exception if the key is nil' do
          @env['params']['mk'] = nil
          @rp.key_valid?(@env['params']).should be_false
        end

        it 'handles an empty array' do
          @env['params']['mk'] = []
          @rp.key_valid?(@env['params']).should be_false
        end

        it 'handles an array of nils' do
          @env['params']['mk'] = [nil, nil, nil]
          @rp.key_valid?(@env['params']).should be_false
        end

        it 'handles an array of blanks' do
          @env['params']['mk'] = ['', '', '']
          @rp.key_valid?(@env['params']).should be_false
        end

        it "doesn't raise if the key provided" do
          @env['params']['mk'] = 'my value'
          @rp.key_valid?(@env['params']).should be_true
        end

        it "doesn't raise if the array contains valid data" do
          @env['params']['mk'] = [1, 2, 3, 4]
          @rp.key_valid?(@env['params']).should be_true
        end

        it "doesn't raise if the key provided is multiline and has blanks" do
          @env['params']['mk'] = "my\n  \nvalue"
          @rp.key_valid?(@env['params']).should be_true
        end

        it "doesn't raise if the key provided is an array and contains multiline with blanks" do
          @env['params']['mk'] = ["my\n  \nvalue", "my\n  \nother\n  \nvalue"]
          @rp.key_valid?(@env['params']).should be_true
        end
      end
    end

    context 'Nested keys tests' do
      before do
        @app = mock('app').as_null_object
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

        @rp.key_valid?(@env['params']).should be_false
      end

      it "return true if key is present" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login' => "user",
          'pass' => "password"}
        }
        }

        @rp.key_valid?(@env['params']).should be_true
      end
    end

    context 'Nested keys tests (with string)' do
      before do
        @app = mock('app').as_null_object
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

        @rp.key_valid?(@env['params']).should be_false
      end

      it "return true if key is present" do
        @env['params'] = {'data' => {
          'credentials' => {
          'login' => "user",
          'pass' => "password"}
        }
        }

        @rp.key_valid?(@env['params']).should be_true
      end
    end

  end

  context "Coerce" do

    it "should only accept a class in the :as" do
      lambda {
        Goliath::Rack::Validation::Param.new(@app, {:key => 'user', :as => "not a class"})
      }.should raise_error
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
            @env['params']['user'].should == value[1]
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
            result.should be_an_instance_of(Array)
            result.first.should == 400
            result.last.should have_key(:error)
          end
        end
      end

      it "should not fail with a invalid input, given a default value" do
        cv = nil
        @env['params']['user'] = "boo"
        lambda {
          cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user',
              :as => Goliath::Rack::Types::Boolean , :default => 'default'})
        }.should_not raise_error
          @env['params']['user'] = 'default'
      end

      it "should be able to take a custom fail message" do
        @env['params']['user'] = "boo"
        cv = Goliath::Rack::Validation::Param.new(@app, {:key => 'user',
            :as => Goliath::Rack::Types::Integer, :message => "custom message"})

        result = cv.call(@env)
        result.should be_an_instance_of(Array)
        result.first.should == 400
        result.last.should have_key(:error)
        result.last[:error].should == "custom message"
      end
    end

  end

  context "Integration" do
    it "should do required param + coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer
      @env['params']['login'] = "3"
      cv.call(@env)
      @env['params']['login'].should == 3

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer
      result = cv.call(@env)
      result.should be_an_instance_of(Array)
      result.first.should == 400
      result.last.should have_key(:error)
    end

    it "should do required param + coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :as => Goliath::Rack::Types::Integer
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      @env['params']['login']['other'].should == 3

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :as => Goliath::Rack::Types::Integer
      result = cv.call(@env)
      result.should be_an_instance_of(Array)
      result.first.should == 400
      result.last.should have_key(:error)
    end

    it "should do required param + not coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login"
      @env['params']['login'] = "3"
      cv.call(@env)
      @env['params']['login'].should == "3"

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login"
      result = cv.call(@env)
      result.should be_an_instance_of(Array)
      result.first.should == 400
      result.last.should have_key(:error)
    end

    it "should do required param + not coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other']
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      @env['params']['login']['other'].should == "3"

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other"
      result = cv.call(@env)
      result.should be_an_instance_of(Array)
      result.first.should == 400
      result.last.should have_key(:error)
    end

    it "should do optional param + coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer, :optional => true
      @env['params']['login'] = "3"
      cv.call(@env)
      @env['params']['login'].should == 3

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :as => Goliath::Rack::Types::Integer, :optional => true
      result = cv.call(@env)
      result.should_not be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param + coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :as => Goliath::Rack::Types::Integer, :optional => true
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      @env['params']['login']['other'].should == 3

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :as => Goliath::Rack::Types::Integer, :optional => true
      result = cv.call(@env)
      result.should_not be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param and not coerce (not nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :optional => true
      @env['params']['login'] = "3"
      cv.call(@env)
      @env['params']['login'].should == "3"

      @env['params']['login'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login",
          :optional => true
      result = cv.call(@env)
      result.should_not be_an_instance_of(Array) #implying its OK
    end

    it "should do optional param and not coerce (nested)" do
      cv = Goliath::Rack::Validation::Param.new @app, :key => ['login', 'other'],
          :optional => true
      @env['params']['login'] = {}
      @env['params']['login']['other'] = "3"
      cv.call(@env)
      @env['params']['login']['other'].should == "3"

      @env['params']['login'] = {}
      @env['params']['login']['other'] = nil
      cv = Goliath::Rack::Validation::Param.new @app, :key => "login.other",
          :optional => true
      result = cv.call(@env)
      result.should_not be_an_instance_of(Array) #implying its OK
    end
  end
end

