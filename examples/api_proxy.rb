#!/usr/bin/env ruby

# Rewrites and proxies requests to a third-party API, with HTTP basic authentication.

$:<< '../lib' << 'lib'

require 'goliath'
require 'em-synchrony/em-http'

class Twilio < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::JSONP

  HEADERS = { authorization: ENV.values_at("TWILIO_SID","TWILIO_AUTH_TOKEN") }
  BASE_URL = "https://api.twilio.com/2010-04-01/Accounts/#{ENV['TWILIO_SID']}/AvailablePhoneNumbers/US"

  def response(env)
    url = "#{BASE_URL}#{env['REQUEST_PATH']}?#{env['QUERY_STRING']}"
    logger.debug "Proxying #{url}"

    http = EM::HttpRequest.new(url).get head: HEADERS
    logger.debug "Received #{http.response_header.status} from Twilio"

    [200, {'X-Goliath' => 'Proxy','Content-Type' => 'application/javascript'}, http.response]
  end
end
