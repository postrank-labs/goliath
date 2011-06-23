#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

#
# A test endpoint that will:
# * with 'delay' parameter, take the given time to respond
# * with 'drop' parameter, drop connection before responding
# * with 'fail' parameter, raise an error of the given type (eg 400 raises a BadRequestError)
# * with 'echo_status', 'echo_headers', or 'echo_body' parameter, replace the given component directly.
#

# If the delay param is given, sleep for that many seconds
#
# Note that though this is non-blocking, the call chain does *not* proceed in parallel
class Delay
  include Goliath::Rack::AsyncMiddleware

  def post_process(env, status, headers, body)
    if delay = env.params['delay']
      delay = [0, [delay.to_f, 5].min].max
      EM::Synchrony.sleep(delay)
      body.merge!(:delay => delay, :actual => (Time.now.to_f - env[:start_time]))
    end
    [status, headers, body]
  end
end

# if the middleware_failure parameter is given, raise an error causing that
# status code
class MiddlewareFailure
  include Goliath::Rack::AsyncMiddleware

  def call(env)
    if code = env.params['fail']
      raise Goliath::Validation::Error.new(code.to_i, "Middleware error #{code}")
    end
    super
  end
end

# if the drop_pre  parameter is given, close the connection before headers are sent
# This works, but probably does awful awful things to Goliath's innards
class DropConnection
  include Goliath::Rack::AsyncMiddleware

  def call(env)
    if env.params['drop'].to_s == 'true'
      env.logger.info "Dropping connection"
      env.stream_close
      [0, {}, '']
    else
      super
    end
  end
end

# if echo_status, echo_headers or echo_body are given, blindly substitute their
# value, clobbering whatever was there.
#
# If you are going to use echo_headers you probably need to use a JSON post body:
#   curl -v -H "Content-Type: application/json" --data-ascii '{"echo_headers":{"X-Question":"What is brown and sticky"},"echo_body":{"answer":"a stick"}}' 'http://127.0.0.1:9001/'
#
class Echo
  include Goliath::Rack::AsyncMiddleware

  def post_process env, status, headers, body
    if env.params['echo_status']
      status = env.params['echo_status'].to_i
    end
    if env.params['echo_headers']
      headers = env.params['echo_headers']
    end
    if env.params['echo_body']
      body = env.params['echo_body']
    end
    [status, headers, body]
  end
end

# Rescue validation errors and send them up the chain as normal non-200 responses
class ExceptionHandler
  include Goliath::Rack::AsyncMiddleware
  include Goliath::Rack::Validator

  def call(env)
    begin
      super
    rescue Goliath::Validation::Error => e
      validation_error(e.status_code, e.message)
    end
  end
end

class TestRig < Goliath::API
  use Goliath::Rack::Tracer             # log trace statistics
  use Goliath::Rack::Params             # parse & merge query and body parameters
  #
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  #
  use ExceptionHandler                  # turn raised errors into HTTP responses
  use MiddlewareFailure                 # make response fail if 'fail' param
  use DropConnection                    # drop connection if 'drop' param
  use Echo                              # replace status, headers or body if 'echo_status' etc given
  use Delay                             # make response take X seconds if 'delay' param

  def on_headers(env, headers)
    env['client-headers'] = headers
  end

  def response(env)
    query_params = env.params.collect { |param| param.join(": ") }
    query_headers = env['client-headers'].collect { |param| param.join(": ") }

    headers = {
      "Special" => "Header",
      "Params"  => query_params.join("|"),
      "Path"    => env[Goliath::Request::REQUEST_PATH],
      "Headers" => query_headers.join("|"),
      "Method"  => env[Goliath::Request::REQUEST_METHOD]}
    [200, headers, headers.dup]
  end
end
