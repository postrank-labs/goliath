#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__), '../lib')
require 'goliath'
require 'em-mongo'
require 'em-http'
require 'em-synchrony/em-http'
require 'yajl/json_gem'

require 'goliath/synchrony/mongo_receiver'            # has the aroundware logic for talking to mongodb
require File.join(File.dirname(__FILE__), 'http_log') # Use the HttpLog as our actual endpoint, but include this in the middleware

# Usage:
#
# First launch a dummy responder, like hello_world.rb or test_rig.rb:
# ruby ./examples/hello_world.rb -sv -p 8080 -e prod &
#
# Then launch this script
# ruby ./examples/auth_and_rate_limit.rb -sv -p 9000 --config $PWD/examples/config/auth_and_rate_limit.rb
#

# Tracks and enforces account and rate limit policies.
#
# Before the request:
#
# * validates the apikey exists
# * launches requests for the account and current usage (hourly rate limit, etc)
#
# It then passes the request down the middleware chain; execution resumes only
# when both the remote request and the auth info have returned.
#
# After remote request and auth info return:
#
# * Check the account exists and is valid
# * Check the rate limit is OK
#
# If it passes all those checks, the request goes through; otherwise we raise an
# error that Goliath::Rack::Validator turns into a 4xx response
#
# WARNING: Since this passes ALL requests through to the responder, it's only
# suitable for idempotent requests (GET, typically).  You may need to handle
# POST/PUT/DELETE requests differently.
#
#
class AuthReceiver < Goliath::Synchrony::MongoReceiver
  include Goliath::Validation
  include Goliath::Rack::Validator
  attr_accessor :account_info, :usage_info

  # time period to aggregate stats over, in seconds
  TIMEBIN_SIZE = 60 * 60

  class MissingApikeyError     < BadRequestError   ; end
  class RateLimitExceededError < ForbiddenError    ; end
  class InvalidApikeyError     < UnauthorizedError ; end

  def pre_process
    validate_apikey!
    first('AccountInfo', { :_id => apikey   }){|res| self.account_info = res }
    first('UsageInfo',   { :_id => usage_id }){|res| self.usage_info   = res }
    env.trace('pre_process_end')
  end

  def post_process
    env.trace('post_process_beg')
    env.logger.info [account_info, usage_info].inspect
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
    return true if usage_info['calls'].to_f <= account_info['max_call_rate'].to_f
    raise RateLimitExceededError
  end

  def charge_usage
    update('UsageInfo', { :_id => usage_id },
      { '$inc' => { :calls   => 1 } }, :upsert => true)
  end

  def inject_headers
    headers.merge!({
        'X-RateLimit-MaxRequests' => account_info['max_call_rate'].to_s,
        'X-RateLimit-Requests'    => usage_info['calls'].to_s,
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
  use Goliath::Rack::AsyncAroundware, AuthReceiver, 'api_auth_db'
end
