require 'goliath'
require 'digest/md5'
require 'postrank-uri'

# Install phantomjs: http://code.google.com/p/phantomjs/wiki/QuickStart
# $> ruby rasterize.rb -sv
# $> curl http://localhost:9000/?url=http://www.google.com (or rather, visit in the browser!)

class Rasterize < Goliath::API

  use Goliath::Rack::Params
  use Goliath::Rack::ValidationError

  use Goliath::Rack::Validation::RequestMethod, %w(GET)
  use Goliath::Rack::Validation::RequiredParam, {:key => 'url'}

  def response(env)
    url = PostRank::URI.clean(params['url'])
    hash = Digest::MD5.hexdigest(PostRank::URI.hash(url, :clean => false))

    if !File.exists? filename(hash)
      fiber = Fiber.current
      EM.system('phantomjs rasterize.js ' + url.to_s + " thumb/#{hash}.png") do |output, status|
        env.logger.info "Phantom exit status: #{status}"
        fiber.resume
      end

      Fiber.yield
    end

    [202, {'X-Phantom' => 'Goliath'}, IO.read(filename(hash))]
  end

  def filename(hash)
    "thumb/#{hash}.png"
  end
end
