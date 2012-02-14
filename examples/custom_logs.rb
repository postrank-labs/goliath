#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

Goliath::Request.log_block = proc do |env, response, elapsed_time|
  method = env[Goliath::Request::REQUEST_METHOD]
  path = env[Goliath::Request::REQUEST_PATH]
  
  env[Goliath::Request::RACK_LOGGER].info("#{method} #{path} in #{'%.2f' % elapsed_time} ms")  
end

class SimpleAPI < Goliath::API
  def response(env)
    [200, {}, "It worked !"]
  end
end

# [19843:INFO] 2012-02-12 18:03:44 :: GET /some/url/ in 4.35 ms
# [19843:INFO] 2012-02-12 18:03:49 :: GET /another/url/ in 4.24 ms
# [19843:INFO] 2012-02-12 18:04:01 :: PUT /another/url/ in 4.16 ms
