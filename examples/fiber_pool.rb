#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'
gem('fiber_pool', '1.0.0')
require 'fiber_pool'

fiber_pool = FiberPool.new(2)

Goliath::Request.execute_block = proc do |&block|
  fiber_pool.spawn(&block)
end


class SimpleAPI < Goliath::API
  def response(env)
    start_time = Time.now.to_f
    EM::Synchrony.sleep(1)
    
    fiber_id = '%#x' % Fiber.current.object_id
    [200, {}, "Request handled by fiber #{fiber_id}"]
  end
end


# ab -n 5 -c 5 http://127.0.0.1:9000/

# [96681:INFO] 2012-01-14 11:35:43 :: Status: 200, Content-Length: 39, Response Time: 1015.46ms
# [96681:INFO] 2012-01-14 11:35:43 :: Status: 200, Content-Length: 39, Response Time: 1005.62ms
# 
# [96681:INFO] 2012-01-14 11:35:44 :: Status: 200, Content-Length: 39, Response Time: 2001.74ms
# [96681:INFO] 2012-01-14 11:35:44 :: Status: 200, Content-Length: 39, Response Time: 2008.55ms
# 
# [96681:INFO] 2012-01-14 11:35:45 :: Status: 200, Content-Length: 39, Response Time: 3005.45ms
# 