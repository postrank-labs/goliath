#!/usr/bin/env ruby

$:.unshift("../lib")

require 'rubygems'
require 'goliath'
require 'rack/supported_media_types'
require 'rack/abstract_format'

class Echo < Goliath::API
  def middleware
    use Rack::ContentLength
    use Goliath::Rack::Params

    use Rack::AbstractFormat

    use Goliath::Rack::DefaultMimeType
    use Rack::SupportedMediaTypes, %w{application/json}

    use Goliath::Rack::Formatters::JSON

    use Goliath::Rack::Render
    use Goliath::Rack::Heartbeat
    use Goliath::Rack::ValidationError

    use Goliath::Rack::Validation::RequestMethod, %w(GET)

    use Goliath::Rack::Validation::RequiredParam, {:key => 'echo', :type => 'Echo'}
  end

  def response(env)
    [200, {}, {:response => env.params['echo']}]
  end
end
