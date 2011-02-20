# Goliath

Goliath is an open source version of the non-blocking Ruby web server framework
powering PostRank. It is a lightweight framework designed to meet the following
goals: bare metal performance, Rack like API and middleware support, simple
configuration, fully asynchronous processing, and readable and maintainable
code (read: no callbacks).

The framework is powered by an EventMachine reactor under the hood and Ryan
Dahl's HTTP parser (same as node.js). The one major advantage Goliath has over
other asynchronous frameworks is the fact that by leveraging Ruby Fibers introduced
in Ruby 1.9+, it can untangle the complicated callback-based code into a format
we are all familiar and comfortable with: linear execution. Each Goliath request
is executed in its own Ruby Fiber and all asynchronous I/O operations can transparently
suspend and later resume the processing without requiring the developer to write
any additional code.

Goliath exposes a raw, bare-metal Rack-like API for developing high throughput
web-services. Request processing is synchronous, and all processing is asynchronous.

## Installation & Prerequisites

* Ruby 1.9.x +
* **gem install goliath**

## Getting Started: Hello World

    require 'goliath'

    class Echo < Goliath::API
      # reload code on every request in dev environment
      use ::Rack::Reloader, 0 if Goliath.dev?

      def response(env)
        [200, {}, "Hello World"]
      end
    end

    > ruby echo.rb -sv
    > [97570:INFO] 2011-02-15 00:33:51 :: Starting server on 0.0.0.0:9000 in development mode. Watch out for stones.

## Goliath Server

Goliath uses its own event based server built on top of EventMachine.
As shown in the above example, to start the server, you just need to
have Ruby execute your Goliath API file. For that, you can pass the
files to the Ruby executable or set a Ruby shebang line in your API
implementation.

The server accepts some optional parameters described below:

Server options:
    -e, --environment NAME           Set the execution environment (prod, dev or test) (default: development)
    -a, --address HOST               Bind to HOST address (default: 0.0.0.0)
    -p, --port PORT                  Use PORT (default: 9000)
    -l, --log FILE                   Log to file (default: off)
    -s, --stdout                     Log to stdout (default: false)
    -P, --pid FILE                   Pid file (default: off)
    -d, --daemonize                  Run daemonized in the background (default: false)
    -v, --verbose                    Enable verbose logging (default: false)
    -h, --help                       Display help message

Note that the default environment could be set in your code using the +Goliath.env=+ method call.

Here is an example of how to start a production Goliath API daemonized
and on port 92010. If not set, the default goliath pid and log files will be used.

    $ ruby awesome_api.rb -e production -p 92010 -d


## Guides

* [Middleware](https://github.com/postrank-labs/goliath/wiki/Middleware)
* [Configuration](https://github.com/postrank-labs/goliath/wiki/Configuration)
* [Plugins](https://github.com/postrank-labs/goliath/wiki/Plugins)

Hands-on applications:

* [Asynchronous HTTP, MySQL, etc](https://github.com/postrank-labs/goliath/wiki/Asynchronous-Processing)
* [Streaming with Goliath](https://github.com/postrank-labs/goliath/wiki/Streaming)
* [Examples](https://github.com/postrank-labs/goliath/tree/master/examples)

## Discussion and Support

* [Source](https://github.com/postrank-labs/goliath)
* [Issues](https://github.com/postrank-labs/goliath/issues)
* [Mailing List](http://groups.google.com/group/goliath-io)

## License & Acknowledgments

Goliath is distributed under the MIT license, for full details please see the LICENSE file.
