require 'spec_helper'
require 'goliath/rack/validation/coerce_value'

describe Goliath::Rack::Validation::CoerceValue do
  before do
    @app = mock('app').as_null_object
    @env = {'params' => {}}
  end

  it "should not allow invalid options" do
    lambda {
      Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :type => Class.new})
    }.should raise_error
  end

  it "uses a default value if key is not supplied" do
    cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:type => Goliath::Rack::Types::Integer })
    cv.key.should == 'id'
  end

  it "uses a default value if as is not supplied" do
    cv = Goliath::Rack::Validation::CoerceValue.new(@app)
    cv.type.should == Goliath::Rack::Types::String

  end

  it "should have default be optional" do
    cv = nil
    lambda {
      cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'flag', :type => Goliath::Rack::Types::Boolean})
    }.should_not raise_error

      cv.default.should == nil

  end

  describe 'with middleware' do
    {
      Goliath::Rack::Types::Boolean  => [['t', true], ['true', true], ['f', false],
                ['false', false], ['1', true],
                ['0', false], ['TRUE', true],  ['FALSE', false],
                ['T', true], ['F', false]
    ],
      Goliath::Rack::Types::Integer => [['24', 24]],
      Goliath::Rack::Types::Float => [['24.3', 24.3]],
      Goliath::Rack::Types::Symbol => [['hi', :hi]],
      Goliath::Rack::Types::String => [["hi", "hi"]],
    }.each do |type, values|
      values.each do |value|
        it "should coerce #{type} from #{value.first} to #{value[1]}" do
          @env['params']['user'] = value.first
          cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :type => type})
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
          cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :type => type})
          cv.call(@env).should == [400, {}, {:error => "#{value} is not a valid #{type.name.split("::").last} or can't convert into a #{type.name.split("::").last}."}]
        end
      end
    end

    it "should not fail with a invalid input, given a default value" do
      cv = nil
      @env['params']['user'] = "boo"
      lambda {
        cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :type => Goliath::Rack::Types::Boolean , :default => 'default'})
      }.should_not raise_error
      @env['params']['user'] = 'default'
    end
  end

end
