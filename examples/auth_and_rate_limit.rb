#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__), '../lib')
require 'goliath'
require 'em-mongo'
require 'em-http'
require 'em-synchrony/em-http'
require 'em-synchrony/em-mongo'
require 'yajl/json_gem'

require File.join(File.dirname(__FILE__), 'http_log') # Use the HttpLog as our actual endpoint, but include this in the middleware

#
# Usage:
#
# First launch the test rig:
#     bundle exec ./examples/test_rig.rb -sv -p 8080 -e prod &
#
# Then launch this script
#     bundle exec ./examples/auth_and_rate_limit.rb -sv -p 9000 --config $PWD/examples/config/auth_and_rate_limit.rb
#
# The auth info is returned in the headers:
#
#   curl -vv 'http://127.0.0.1:9000/?_apikey=i_am_busy&drop=false' ; echo
#   ...snip...
#   < X-RateLimit-MaxRequests: 1000
#   < X-RateLimit-Requests: 999
#   < X-RateLimit-Reset: 1312059600
#
# This user will hit the rate limit after 10 requests:
#
#     for foo in 1 2 3 4 5 6 7 8 9 10 11 12 ; do echo -ne $foo "\t" ; curl 'http://127.0.0.1:9000/?_apikey=i_am_limited' ; echo ; done
#     1   {"Special":"Header","Params":"_apikey: i_am_awesome|drop: false","Path":"/","Headers":"User-Agent: ...
#     ...
#     11  [:error, "Your request rate (11) is over your limit (10)"]
#
# You can test the barrier (both delays are in fractional seconds):
# * drop=true     will drop the request at the remote host
# * auth_db_delay will fake a slow response from the mongo
# * delay         will cause a slow response from the remote host
#
#     time curl -vv 'http://127.0.0.1:9000/?_apikey=i_am_awesome&drop=false&delay=0.4&auth_db_delay=0.3'
#     ...
#     X-Tracer: ... received_usage_info: 0.06, received_sleepy: 299.52, received_downstream_resp: 101.67, ..., total: 406.09
#     ...
#     real      0m0.416s        user    0m0.002s        sys     0m0.003s        pct     1.24
#
# This shows the mongodb response returning quickly, the fake DB delay returning
# after 300ms, and the downstream response returning after an additional 101 ms.
# The total request took 416ms of wall-clock time
#
# This will hold up even in the face of many concurrent connections. Relaunch in
# production (you may have to edit the config/auth_and_rate_limit scripts):
#
#     bundle exec ./examples/auth_and_rate_limit.rb -sv -p 9000 -e prod --config $PWD/examples/config/auth_and_rate_limit.rb
#
# On my laptop, with 20 concurrent requests (each firing two db gets, a 400 ms
# http get, and two db writes), the median/90%ile times were 431ms / 457ms:
#
#     time ab -c20 -n20 'http://127.0.0.1:9000/?_apikey=i_am_awesome&drop=false&delay=0.4&auth_db_delay=0.3'
#     ...
#     Percentage of the requests served within a certain time (ms)
#     50%    431
#     90%    457
#     real      0m0.460s        user    0m0.001s        sys     0m0.003s        pct     0.85
#
# With 100 concurrent requests, the request latency starts to drop but the
# throughput and variance stand up:
#
#     time ab -c100 -n100 'http://127.0.0.1:9000/?_apikey=i_am_awesome&drop=false&delay=0.4&auth_db_delay=0.3'
#     ...
#     Percentage of the requests served within a certain time (ms)
#     50%    640
#     90%    673
#     real      0m0.679s        user    0m0.002s        sys     0m0.007s        pct     1.33
#

# Tracks and enforces account and rate limit policies.
#
# This is like a bouncer who lets you order a drink while he checks your ID. We
# proxy your request to a backend server and get your account/usage info; if
# your ID is good there's no further wait on a response.
#
# This works through the magic of BarrierAroundware:
#
# 1) In pre_process (before the request):
#    * validate an apikey was given; if not, raise (returning directly)
#    * launch requests for the account and rate limit usage
#
# 2) BarrierAroundwareFactory passes the request down the middleware chain
#
# 3) post_process resumes only when both proxied request & auth info are complete
#
# 4) The post_process method then
#    - Checks the account exists and is valid
#    - Checks the rate limit is OK
#
# 5) If it passes all those checks, the request goes through; otherwise we raise
#    an error that Goliath::Rack::Validator turns into a 4xx response
#
# WARNING: Since this passes ALL requests through to the responder, it's only
# suitable for idempotent requests (GET, typically).  You may need to handle
# POST/PUT/DELETE requests differently.
#
#
class AuthBarrier
  include Goliath::Rack::BarrierAroundware
  include Goliath::Validation
  attr_reader   :db
  attr_accessor :account_info, :usage_info

  # time period to aggregate stats over, in seconds
  TIMEBIN_SIZE = 60 * 60

  class MissingApikeyError     < BadRequestError   ; end
  class RateLimitExceededError < ForbiddenError    ; end
  class InvalidApikeyError     < UnauthorizedError ; end

  def initialize(env, db_name)
    @db = env.config[db_name]
    super(env)
  end

  def pre_process
    env.trace('pre_process_beg')
    validate_apikey!

    # the results of the afirst deferrable will be set right into account_info (and the request into successes)
    enqueue_mongo_request(:account_info, { :_id => apikey   })
    enqueue_mongo_request(:usage_info,   { :_id => usage_id })

    # Fake out a delay in the database response if auth_db_delay is given
    if (auth_db_delay = env.params['auth_db_delay'].to_f) > 0
      enqueue_acceptor(:sleepy){|acc| EM.add_timer(auth_db_delay){ acc.succeed } }
    end

    env.trace('pre_process_end')
    return Goliath::Connection::AsyncResponse
  end

  def post_process
    env.trace('post_process_beg')

    # When post_process resumes, the db requests and the response are here!
    # [:account_info, :usage_info, :status, :headers, :body].each{|attr| env.logger.info(("%23s\t%s" % [attr, self.send(attr).inspect[0..200]])) }

    self.account_info ||= {}
    self.usage_info   ||= {}

    inject_headers

    EM.next_tick do
      safely(env){ charge_usage }
    end

    safely(env, headers) do
      check_apikey!
      check_rate_limit!

      env.trace('post_process_end')
      [status, headers, body]
    end
  end

  if defined?(EM::Mongo::Cursor)
    # em-mongo > 0.3.6 gives us a deferrable back. nice and clean.
    def enqueue_mongo_request(handle, query)
      enqueue handle, db.collection(handle).afirst(query)
    end
  else
    # em-mongo <= 0.3.6 makes us fake a deferrable response.
    def enqueue_mongo_request(handle, query)
      enqueue_acceptor(handle) do |acc|
        db.collection(handle).afind(query){|resp| acc.succeed(resp.first) }
      end
    end
  end

  def accept_response(handle, *args)
    env.trace("received_#{handle}")
    super(handle, *args)
  end

  # ===========================================================================

  def validate_apikey!
    if apikey.to_s.empty?
      raise MissingApikeyError
    end
  end

  def check_apikey!
    unless account_info['valid'] == true
      raise InvalidApikeyError
    end
  end

  def check_rate_limit!
    rate  = usage_info['calls'].to_i + 1
    limit = account_info['max_call_rate'].to_i
    return true if rate <= limit
    raise RateLimitExceededError, "Your request rate (#{rate}) is over your limit (#{limit})"
  end

  def charge_usage
    db.collection(:usage_info).update({ :_id => usage_id },
      { '$inc' => { :calls   => 1 } }, :upsert => true)
  end

  def inject_headers
    headers.merge!({
        'X-RateLimit-MaxRequests' => account_info['max_call_rate'].to_s,
        'X-RateLimit-Requests'    => usage_info['calls'].to_i.to_s,
        'X-RateLimit-Reset'       => timebin_end.to_s,
      })
  end

  # ===========================================================================

  def apikey
    env.params['_apikey']
  end

  def usage_id
    "#{apikey}-#{timebin}"
  end

  def timebin
    @timebin ||= timebin_beg
  end

  def timebin_beg
    ((Time.now.to_i / TIMEBIN_SIZE).floor * TIMEBIN_SIZE)
  end

  def timebin_end
    timebin_beg + TIMEBIN_SIZE
  end
end

class AuthAndRateLimit < HttpLog
  use Goliath::Rack::Tracer, 'X-Tracer'
  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::BarrierAroundwareFactory, AuthBarrier, 'api_auth_db'
end
