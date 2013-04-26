# HISTORY

# v1.0.2 (April 25th 2013)
  - Added a handle to disable server startup on exit
  - Added support for JSON post bodies that are not a hash
  - Added a setup hook for API's
  - See full list @ https://github.com/postrank-labs/goliath/compare/v1.0.1...v1.0.2

# v1.0.1 (November 8, 2012)

  - integrated console (CLI flag)
  - log shutdown sequence

## v1.0.0 (August 11, 2012)

  - Improved WebSocket handling
  - New Coerce middleware to simplify query & post body processing
  - Improved exception logging: full logging in dev, limited in prod mode
  - Exception messages are now returned on 500's (instead of fixed message)
  - Can specify custom logger for spec output
  - Signal handling fixes for Windows
  - HeartBeat middleware accepts :no_log => true
  - Can specify own log_block to customize logging output
  - Added support for PATCH and OPTIONS http methods
  - Load plugins in test server by default
  - Allow arbitrary runtime environments
  - New Goliath.env? method to detect current environment
  - cleanup of spec helpers
  - many small bugfixes...

  - All query params are now strings, symbol access is removed
  - Validation middleware no longer defaults to "id" for key - specify own
  - **Router is removed in 1.0** - discussion on [Google group](https://groups.google.com/d/topic/goliath-io/SZxl78BNhUM/discussion)

## v0.9.3 (Oct 16, 2011)

  - new router DSL - much improved, see examples
  - refactored async_aroundware
  - make jruby friendlier (removed 1.9 req in gemspec)
  - enable epoll
  - SSL support
  - unix socket support
  - reload config on HUP
  - and a number of small bugfixes + other improvements..
  - See full list @ https://github.com/postrank-labs/goliath/compare/v0.9.2...v0.9.3

## v0.9.2 (July 21, 2011)

  - See full list @ https://github.com/postrank-labs/goliath/compare/v0.9.1...v0.9.2

## v0.9.1 (Apr 12, 2011)

  - Added extra messaging around the class not matching the file name (Carlos Brando)

  - Fix issue with POST parameters not being parsed by Goliath::Rack::Params
  - Added support for multipart encoded POST bodies
  - Added support for parsing nested query string parameters (Nolan Evans)
  - Added support for parsing application/json POST bodies
  - Content-Types outside of multipart, urlencoded and application/json will not be parsed automatically.

  - added 'run as user' option
  - SERVER_NAME and SERVER_PORT are set to values in HOST header

  - Cleaned up spec examples (Justin Ko)

  - moved logger into 'rack.logger' key to be more Rack compliant (Env#logger added to
    keep original API consistent)
  - add command line option for specifying config file
  - HTTP_CONTENT_LENGTH and HTTP_CONTENT_TYPE were changed to CONTENT_TYPE and CONTENT_LENGTH
    to be more Rack compliant
  - fix issue with loading config file in development mode

  - Rack::Reloader will be loaded automatically by the framework in development mode.


## v0.9.0 (Mar 9, 2011)

(Initial Public Release)

Goliath is an open source version of the non-blocking (asynchronous) Ruby web server framework
powering PostRank. It is a lightweight framework designed to meet the following goals: bare
metal performance, Rack API and middleware support, simple configuration, fully asynchronous
processing, and readable and maintainable code (read: no callbacks).

The framework is powered by an EventMachine reactor, a high-performance HTTP parser and Ruby 1.9
runtime. One major advantage Goliath has over other asynchronous frameworks is the fact that by
leveraging Ruby fibers, it can untangle the complicated callback-based code into a format we are
all familiar and comfortable with: linear execution, which leads to more maintainable and readable code.

While MRI is the recommend platform, Goliath has been tested to run on JRuby and Rubinius.

Goliath has been in production at PostRank for over a year, serving a sustained 500 requests/s for
internal and external applications. Many of the Goliath processes have been running for months at
a time (read: no memory leaks) and have served hundreds of gigabytes of data without restarts. To
scale up and provide failover and redundancy, our individual Goliath servers at PostRank are usually
deployed behind a reverse proxy (such as HAProxy).
