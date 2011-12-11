require 'spec_helper'
require 'goliath/rack/validation/coerce_value'

describe Goliath::Rack::Validation::CoerceValue do
  before do
    @app = mock('app').as_null_object
    @env = {'params' => {}}
  end

  it "should not allow invalid options" do
    lambda {
      Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :as => :something_not_valid})
    }.should raise_error
  end

  it "uses a default value if key is not supplied" do
    cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:as => :integer})
    cv.key.should == 'id'
  end

  it "uses a default value if as is not supplied" do
    cv = Goliath::Rack::Validation::CoerceValue.new(@app)
    cv.as.should == :string
  end

  it "should have default be optional" do
    cv = nil
    lambda {
      cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :as => :bool})
    }.should_not raise_error

      cv.default.should == nil

  end

  describe 'with middleware' do
    {
      :bool => [['t', true], ['true', true], ['f', false],
                ['false', false], ['1', true],
                ['0', false], ['TRUE', true],  ['FALSE', false],
                ['T', true], ['F', false]
    ],
      :boolean => [['t', true], ['true', true], ['f', false],
                   ['false', false], ['1', true],
                   ['0', false], ['TRUE', true],  ['FALSE', false],
                   ['T', true], ['F', false]
    ],
      :int => [['24', 24]],
      :integer => [['24', 24]],
      :string => [["hi", "hi"]],
      :json => [
        ['[1,2,3]', [1,2,3]],
        ['{"a" : 3}', {'a' => 3}]
    ]
    }.each do |type, values|
      values.each do |value|
        it "should coerce #{type} from #{value.first} to #{value[1]}" do
          @env['params']['user'] = value.first
          cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :as => type})
          cv.call(@env)
          @env['params']['user'].should == value[1]
        end
      end
    end

    {
      :bool => ["235", "hi", "3"],
      :boolean => ["235", "hi", "3"],
      :int => ["hi", "false", "true"],
      :integer => ["hi", "false", "true"],
      :json => ["{b : 3}", "{[[][][]]}"]
    }.each do |type, values|
      values.each do |value|
        it "should not coerce #{type} with #{value}" do
          @env['params']['user'] = value
          cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :as => type})
          cv.call(@env).should == [400, {}, {:error => "user is not a valid #{type}"}]
        end
      end
    end

    it "should not fail with a invalid input, given a default value" do
      cv = nil
      @env['params']['user'] = "boo"
      lambda {
        cv = Goliath::Rack::Validation::CoerceValue.new(@app, {:key => 'user', :as => :boolean, :default => 'default'})
      }.should_not raise_error
      @env['params']['user'] = 'default'
    end
  end

end
