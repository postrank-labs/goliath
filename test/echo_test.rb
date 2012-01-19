require 'test_helper'

class Echo < Goliath::API
  use Goliath::Rack::Params

  def response(env)
    [200, {}, env.params['echo']]
  end
end

class EchoTest < Test::Unit::TestCase
  include Goliath::TestHelper

  def setup
    @err = Proc.new { assert false, "API request failed" }
  end

  def test_query_is_echoed_back
    with_api(Echo) do
      get_request({:query => {:echo => 'test'}}, @err) do |c|
        assert_equal 'test', c.response
      end
    end
  end
end