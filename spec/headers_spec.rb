require 'spec_helper'
require 'goliath/headers'

describe Goliath::Headers do
  before(:each) do
    @h = Goliath::Headers.new
  end

  it 'outputs in the correct format' do
    @h['my_header'] = 'my_value'
    @h.to_s.should == "my_header: my_value\r\n"
  end

  it 'suppresses duplicate keys' do
    @h['my_header'] = 'my_value1'
    @h['my_header'] = 'my_value2'
    @h.to_s.should == "my_header: my_value1\r\n"
  end

  it 'returns true if a key has been set' do
    @h['my_header'] = 'my_value'
    @h.has_key?('my_header').should be_true
  end

  it 'returns false if the key has not been set' do
    @h.has_key?('my_header').should be_false
  end

  it 'ignores nil values' do
    @h['my_header'] = nil
    @h.to_s.should == ''
  end

  it 'allows a value after setting nil' do
    @h['my_header'] = nil
    @h['my_header'] = 'my_value'
    @h.to_s.should == "my_header: my_value\r\n"
  end

  it 'formats time as an http time' do
    time = Time.now
    @h['my_time'] = time
    @h.to_s.should == "my_time: #{time.httpdate}\r\n"
  end

  %w(Set-Cookie Set-Cookie2 Warning WWW-Authenticate).each do |key|
    it "allows #{key} as to be duplicate" do
      @h[key] = 'value1'
      @h[key] = 'value2'
      @h.to_s.should == "#{key}: value1\r\n#{key}: value2\r\n"
    end
  end
end
