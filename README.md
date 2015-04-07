# Goliath

[<img src="https://secure.travis-ci.org/postrank-labs/goliath.png?travis"/>](http://travis-ci.org/postrank-labs/goliath) [<img src="https://gemnasium.com/postrank-labs/goliath.png?travis"/>](https://gemnasium.com/postrank-labs/goliath)

Goliath is an open source version of the non-blocking (asynchronous) Ruby web server framework. It is a lightweight framework designed to meet the following goals: bare metal performance, Rack API and middleware support, simple configuration, fully asynchronous processing, and readable and maintainable code (read: no callbacks).

The framework is powered by an EventMachine reactor, a high-performance HTTP parser and Ruby 1.9+ runtime. The one major advantage Goliath has over other asynchronous frameworks is the fact that by leveraging Ruby fibers introduced in Ruby 1.9+, it can untangle the complicated callback-based code into a format we are all familiar and comfortable with: linear execution, which leads to more maintainable and readable code.

Each HTTP request within Goliath is executed within its own Ruby fiber and all asynchronous I/O operations can transparently suspend and later resume the processing without requiring the developer to write any additional code. Both request processing and response processing can be done in fully asynchronous fashion: streaming uploads, firehose API's, request/response, websockets, and so on.

## Installation & Prerequisites

* Install Ruby 1.9 (via RVM or natively)

```bash
$> gem install rvm
$> rvm install 1.9.3
$> rvm use 1.9.3
```

* Install Goliath:

```bash
$> gem install goliath
```

## Getting Started: Hello World

```ruby
require 'goliath'

class Hello < Goliath::API
  def response(env)
    [200, {}, "Hello World"]
  end
end

> ruby hello.rb -sv
> [97570:INFO] 2011-02-15 00:33:51 :: Starting server on 0.0.0.0:9000 in development mode. Watch out for stones.
```

See examples directory for more hands-on examples of building Goliath powered web-services.

## Performance: MRI, JRuby, Rubinius

Goliath is not tied to a single Ruby runtime - it is able to run on MRI Ruby, JRuby and Rubinius today. Depending on which platform you are working with, you will see different performance characteristics. At the moment, we recommend MRI Ruby 1.9.3+ as the best performing VM: a roundtrip through the full Goliath stack on MRI 1.9.3 takes ~0.33ms (~3000 req/s).

Goliath has been used in production environments for 2+ years, across many different companies: PostRank (now Google), [OMGPOP](OMGPOP) (now Zynga), [GameSpy](http://www.poweredbygamespy.com/2011/09/09/growing-pains-they-hurt-so-good/), and many others.

## FAQ

* How does Goliath compare to other Ruby async app-servers like Thin?
    * They are similar (both use Eventmachine reactor), but also very different. Goliath is able to run on different Ruby platforms (see above), uses a different HTTP parser, supports HTTP keepalive & pipelining, and offers a fully asynchronous API for both request and response processing.

* How does Goliath compare to Mongrel, Passenger, Unicorn?
    * Mongrel is a threaded web-server, and both Passenger and Unicorn fork an entire VM to isolate each request from each other. By contrast, Goliath builds a single instance of the Rack app and runs all requests in parallel through a single VM, which leads to a much smaller memory footprint and less overhead.

* How do I deploy Goliath in production?
    * We recommend deploying Goliath behind a reverse proxy such as HAProxy ([sample config](https://github.com/postrank-labs/goliath/wiki/HAProxy)), Nginx or equivalent. Using one of the above, you can easily run multiple instances of the same application and load balance between them within the reverse proxy.

## Guides

* [Server Options](https://github.com/postrank-labs/goliath/wiki/Server)
* [Middleware](https://github.com/postrank-labs/goliath/wiki/Middleware)
* [Configuration](https://github.com/postrank-labs/goliath/wiki/Configuration)
* [Plugins](https://github.com/postrank-labs/goliath/wiki/Plugins)
* [Zero Downtime Restart](https://github.com/postrank-labs/goliath/wiki/Zero-downtime-restart)


### Hands-on applications:

If you are you new to EventMachine, or want a detailed walk-through of building a Goliath powered API? You're in luck, a super-awesome Pluralsight screencast which will teach you all you need to know:

* [Meet EventMachine](http://www.pluralsight.com/courses/meet-eventmachine) - introduction to EM, Fibers, building an API with Goliath

Additionally, you can also watch this presentation from GoGaRuCo 2011, which describes the design and motivation behind Goliath:

* [0-60 with Goliath: Building high performance web services](http://confreaks.com/videos/653-gogaruco2011-0-60-with-goliath-building-high-performance-ruby-web-services)

Other resources:

* [Asynchronous HTTP, MySQL, etc](https://github.com/postrank-labs/goliath/wiki/Asynchronous-Processing)
* [Response streaming with Goliath](https://github.com/postrank-labs/goliath/wiki/Streaming)
* [Examples](https://github.com/postrank-labs/goliath/tree/master/examples)

## Discussion and Support

* [Source](https://github.com/postrank-labs/goliath)
* [Issues](https://github.com/postrank-labs/goliath/issues)
* [Mailing List](http://groups.google.com/group/goliath-io)

## License & Acknowledgments

Goliath is distributed under the MIT license, for full details please see the LICENSE file.
