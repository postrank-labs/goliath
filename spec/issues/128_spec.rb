require 'spec_helper'

class Issue128Responds < Goliath::API
  use Goliath::Rack::Validation::Param, :key => 'feedback', :message => "comes from a mindless computer. It should always be the same."
  def response(env)
    [201, {}, []]
  end
end

class Issue128 < Goliath::API
  post "/issue128", Issue128Responds
  def response(env)
    raise RuntimeException.new("#response is ignored when using maps, so this exception won't raise. See spec/integration/rack_routes_spec.")
  end
end

describe Issue128, :status => :open do
  before(:all) do
    @bad_post_response = 'key option required'
  end
  let(:err) { Proc.new { fail "API request failed" } }

  context 'repeated empty POST requests' do
    it 'should always give the same response' do
      with_api(Issue128) do
        post_request({}, err) do |c|
          c.response.should match /It should always be the same/
        end
      end
      with_api(Issue128) do
        post_request({}, err) do |c|
          c.response.should_not match /#{@bad_post_response}/
        end
      end
      with_api(Issue128) do
        post_request({}, err) do |c|
          pp c.response
          c.response.should match /It should always be the same/
        end
      end
    end
  end

end
