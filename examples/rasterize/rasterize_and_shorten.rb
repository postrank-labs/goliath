#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'
require File.dirname(__FILE__)+'/rasterize'
require File.dirname(__FILE__)+'/../favicon'

require 'goliath'
require 'em-synchrony/em-http'
require 'postrank-uri'

#
# Aroundware: while the Rasterize API is processing, this uses http://is.gd to
# generate a shortened link, stuffing it in the header. Both requests happen
# simultaneously.
#
class ShortenURL
  include Goliath::Rack::BarrierAroundware
  SHORTENER_URL_BASE = 'http://is.gd/create.php'
  attr_accessor :shortened_url

  def pre_process
    target_url = PostRank::URI.clean(env.params['url'])
    shortener_request = EM::HttpRequest.new(SHORTENER_URL_BASE).aget(:query => { :format => 'simple', :url => target_url })
    enqueue :shortened_url, shortener_request
    return Goliath::Connection::AsyncResponse
  end

  def post_process
    if shortened_url
      headers['X-Shortened-URI'] = shortened_url.response
    end
    [status, headers, body]
  end
end

class RasterizeAndShorten < Rasterize
  use Goliath::Rack::Params
  use Favicon, File.expand_path(File.dirname(__FILE__)+"/../public/favicon.ico")
  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'url'}
  #
  use Goliath::Rack::BarrierAroundwareFactory, ShortenURL
end
