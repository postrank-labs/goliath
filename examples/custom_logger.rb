#!/usr/bin/env ruby
$:<< '../lib' << 'lib'

require 'goliath'

class CustomLogger < Goliath::API
  def setup_logger(logger, opts)
    log_format = Log4r::PatternFormatter.new(:pattern => "%d :: %m")
    logger.add(Log4r::StdoutOutputter.new('console', :formatter => log_format))
  end

  def response(env)
    [200, {}, "OK"]
  end
end