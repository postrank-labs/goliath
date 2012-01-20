#!/usr/bin/env ruby
$:<< '../../lib' << '../lib' << 'lib' << './'

# Newrelic_stats.rb
# a simple example that shows how to integrate New Relic reporting in your Goliath app
#
# Usage:
#
# $ gem install newrelic_rpm
# require 'newrelic_rpm'
#
# - edit the newrelic.yml file, setting appropriate preferences and license key
# - place method tracers (see notes below) as the first line of all methods you wish to report
# - perform a newrelic agent manual start as shown in the config file for this example
#
# $ ruby newrelic_stats.rb -sv
#
# ...if all goes well, you should see this output upon startup:
#
#   :: Starting server on 0.0.0.0:9000 in development mode. Watch out for stones.
#   Connected to NewRelic Service at collector-8.newrelic.com:80
#
#
# Notes:
#
# To have the newrelic_stats_reporter middleware effectively report overall execution time of
# your code with performance breakdown of each method, place a well-named "trace" method as the
# first line in the execution of every method in your code: trace("Classname#Methodname")
#
# The middleware will create custom metric data for each of the collected traces, and send scoped and
# and unscoped data points to New Relic. the events appear in both the app overview and in
# the performance breakdown charts. this will also allow your New Relic app to take advantage of
# certain rollup processing that occurs over time in your reported data.
#
# IMPORTANT: Total response time, number of requests, and request per second (with performance breakdowns)
# will _only_ be effectively reported if every method exercised in your code contains a method tracer call.
# Be sure that all code that runs in your app is properly traced!
#
# If you use middleware from the Goliath source, be aware that the execution time of your app
# may be under-reported by a few milliseconds, since no trace calls are present in the Goliath source.
# If to-the-millisecond accuracy is absolutely required, you may need to add in your own trace calls
# to the Goliath source, or create your own middlewares from the source and add traces where necessary.
#

require 'goliath'
require 'newrelic_rpm'
require 'middleware/newrelic_stats_reporter'

class ExampleEndpoint < Goliath::API
  def on_headers(env, headers)
    trace("ExampleEndpoint#on_headers")
    logger.info("headers: #{headers.to_s}")
    # not really doing anything here, just an example to show the importance
    # of adding tracers as the first line every method in your app's code
  end

  def response(env)
    trace("ExampleEndpoint#response")
    # simulating some awesome work here with a random delay
    random_delay
    [200, {}, "Processing Complete!"]
  end

  def random_delay
    delay = Random.rand(10.0) / 1000.0
    logger.info(delay)
    EM::Synchrony.sleep(delay)
  end

end

class NewrelicStats < Goliath::API

  use Examples::Rack::NewrelicStatsReporter # handles sending off all recorded stats to New Relic
                                            # NOTE: if you have multiple custom middlewares,
                                            # make sure this is the _first_ middleware included
                                            # so that it is the last middleware called in the chain

  use Goliath::Rack::Heartbeat              # respond to /status with 200, OK
  use Goliath::Rack::Params                 # parse all params in query strings

  get '/example', ExampleEndpoint

end
