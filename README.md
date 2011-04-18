# Goliath

Goliath is an open source version of the non-blocking (asynchronous) Ruby web server framework powering PostRank. It is a lightweight framework designed to meet the following goals: bare metal performance, Rack API and middleware support, simple configuration, fully asynchronous processing, and readable and maintainable code (read: no callbacks).

The framework is powered by an EventMachine reactor, a high-performance HTTP parser and Ruby 1.9 runtime. The one major advantage Goliath has over other asynchronous frameworks is the fact that by leveraging Ruby fibers introduced in Ruby 1.9+, it can untangle the complicated callback-based code into a format we are all familiar and comfortable with: linear execution, which leads to more maintainable and  readable code.

Each HTTP request within Goliath is executed in its own Ruby fiber and all asynchronous I/O operations can transparently suspend and later resume the processing without requiring the developer to write any additional code. Both request processing and response processing can be done in fully asynchronous fashion: streaming uploads, firehose API's, request/response, and so on.

## Installation & Prerequisites

* Install Ruby 1.9 (via RVM or natively)

        $> gem install rvm
        $> rvm install 1.9.2
        $> rvm use 1.9.2

* Install Goliath:

        $> gem install goliath

## Getting Started: Hello World

    require 'goliath'

    class Hello < Goliath::API
      def response(env)
        [200, {}, "Hello World"]
      end
    end

    > ruby hello.rb -sv
    > [97570:INFO] 2011-02-15 00:33:51 :: Starting server on 0.0.0.0:9000 in development mode. Watch out for stones.

See examples directory for more, hands-on examples of building Goliath powered web-services.

## Performance: MRI, JRuby, Rubinius

Goliath is not tied to a single Ruby runtime - it is able to run on MRI Ruby, JRuby and Rubinius today. Depending on which platform you are working with, you will see different performance characteristics. At the moment, we recommend MRI Ruby 1.9.2 as the best performing VM: a roundtrip through the full Goliath stack on MRI 1.9.2p136 takes ~0.33ms (~3000 req/s).

JRuby performance (with 1.9 mode enabled) is currently much worse than MRI Ruby 1.9.2, due to the fact that all JRuby fibers are mapped to native Java threads. However, there is [very promising](http://classparser.blogspot.com/2010/04/jruby-coroutines-really-fast.html), existing work that promises to make JRuby fibers even faster than those of MRI Ruby. Once this functionality is built into JRuby ([JRUBY-5461](http://jira.codehaus.org/browse/JRUBY-5461)), JRuby may well take the performance crown. At the moment, without the MLVM support, a request through the full Goliath stack takes ~6ms (166 req/s).

Rubinius + Goliath performance is tough to pin down - there is a lot of room for optimization within the Rubinius VM. Currently, requests can take as little as 0.2ms and later spike to 50ms+. Stay tuned!

Goliath has been in production at PostRank for over a year, serving a sustained 500 requests/s for internal and external applications. Many of the Goliath processes have been running for months at a time (read: no memory leaks) and have served hundreds of gigabytes of data without restarts. To scale up and provide failover and redundancy, our individual Goliath servers at PostRank are usually deployed behind a reverse proxy (such as HAProxy).

## FAQ

* How does Goliath compare to other Ruby async app-servers like Thin?
    * They are similar (both use Eventmachine reactor), but also very different. Goliath is able to run on different Ruby platforms (see above), uses a different HTTP parser, supports HTTP keepalive & pipelining, and offers a fully asynchronous API for both request and response processing.

* How does Goliath compare to Mongrel, Passenger, Unicorn?
    * Mongrel is a threaded web-server, and both Passenger and Unicorn fork an entire VM to isolate each request from each other. By contrast, Goliath builds a single instance of the Rack app and runs all requests in parallel through a single VM, which leads to a much smaller memory footprint and less overhead.

* How do I deploy Goliath in production?
    * We recommend deploying Goliath behind a reverse proxy such as HAProxy, Nginx or equivalent. Using one of the above, you can easily run multiple instances of the same application and load balance between them within the reverse proxy.

## Guides

* [Server Options](https://github.com/postrank-labs/goliath/wiki/Server)
* [Middleware](https://github.com/postrank-labs/goliath/wiki/Middleware)
* [Configuration](https://github.com/postrank-labs/goliath/wiki/Configuration)
* [Plugins](https://github.com/postrank-labs/goliath/wiki/Plugins)

### Hands-on applications:

* [Asynchronous HTTP, MySQL, etc](https://github.com/postrank-labs/goliath/wiki/Asynchronous-Processing)
* [Response streaming with Goliath](https://github.com/postrank-labs/goliath/wiki/Streaming)
* [Examples](https://github.com/postrank-labs/goliath/tree/master/examples)

## Coverage

* [Goliath: Non-blocking, Ruby 1.9 Web Server](http://www.igvita.com/2011/03/08/goliath-non-blocking-ruby-19-web-server)
* [Stage left: Enter Goliath - HTTP Proxy + MongoDB](http://everburning.com/news/stage-left-enter-goliath/)
* [InfoQ: Meet the Goliath of Ruby Application Servers](http://www.infoq.com/articles/meet-goliath)
* [Node.jsはコールバック・スパゲティを招くか](http://el.jibun.atmarkit.co.jp/rails/2011/03/nodejs-d123.html)
* [Goliath on LinuxFr.org (french)](http://linuxfr.org/news/en-vrac-spécial-ruby-jruby-sinatra-et-goliath)
* [Goliath et ses amis (slides in french)](http://nono.github.com/Presentations/20110416_Goliath/)

## Discussion and Support

* [Source](https://github.com/postrank-labs/goliath)
* [Issues](https://github.com/postrank-labs/goliath/issues)
* [Mailing List](http://groups.google.com/group/goliath-io)

## License & Acknowledgments

Goliath is distributed under the MIT license, for full details please see the LICENSE file.
