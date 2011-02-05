# Goliath

Goliath is an API framework. Goliath is designed to serve a single type of API, be it a
feed API, log API or search API. While similar to Rails and Sinatra, Goliath is more inclined
to return JSON or XML responses instead of HTML. Goliath sits behind your Sinatra or Rails
application and feeds data back them for display.

While rack-aware, Goliath is not 100% rack compliant. We make some modifications and take
some short cuts in order to get what we want out of the framework.

***

## Features

 * Asynchronous execution from the ground up.
 * Rack-aware, but not rack compliant.
 * Plugins.

***

## Requirements

 * Ruby 1.9.2 or greater
 * [eventmachine](http://rubyeventmachine.org)
 * EM-Synchrony
 * Rack
 * Rack-Contrib
 * Async-Rack
 * Rack-Respond_to
 * Log4r
 * Yajl

***

## Getting Started

Let's create an echo server with Goliath. I'm adding a bit of validation and a few other things
in order to show some of the features in the framework.

    #!/usr/bin/env ruby

    require 'rubygems'
    require 'goliath'
    require 'rack/supported_media_types'
    require 'rack/abstract_format'

    class Echo < Goliath::API
      use Goliath::Rack::Params

      use Rack::AbstractFormat

      use Goliath::Rack::DefaultMimeType
      use Rack::SupportedMediaTypes, %w{application/json}

      use Goliath::Rack::Formatters::JSON

      use Goliath::Rack::Render
      use Goliath::Rack::Heartbeat
      use Goliath::Rack::ValidationError

      use Goliath::Rack::Validation::RequestMethod, %w(GET)

      use Goliath::Rack::Validation::RequiredParam, {:key => 'echo'}

      def response(env)
        [200, {}, {:response => env.params['echo']}]
      end
    end

So, what's going on here. First off, skipping the requires, all Goliath applications will
inherit from `Goliath::API`. This will do some initial setup for us and create the _Fiber_
that the API will execute within.

Next up we setup the middleware we want to use. The middleware is defined directly
inside the API file. By default, `Rack::ContentLength` will be included in all applications.
The Goliath middleware are:

 * __Goliath::Rack::Params__ : The default params parser. Will setup env.params for us with the URL and POST parameters.
 * __Goliath::Rack::DefaultMimeType__ : Makes sure a MIME type is always specified.
 * __Goliath::Rack::Formatters::JSON__ : Formatter for application/json requests.
 * __Goliath::Rack::Render__ : Sets the correct Content-Type for the response.
 * __Goliath::Rack::Heartbeat__ : Adds a /status handler that responds with OK. For monitoring purposes.
 * __Goliath::Rack::ValidationError__ : Generic handler for all error responses.
 * __Goliath::Rack::Validation::RequestMethod__ : Validates we only respond to GET requests.
 * __Goliath::Rack::Validation::RequiredParam__ : Validates the *echo* param is provided to the API.

Finally, we implement the `def response(env)` method. This method is required and is executed with the
fiber setup by the API super class. We return the triple of _response_code_, _headers_, and _body_.

If we save and execute (-s is for standard out logging, -v is verbose logging):

    dj2@titania ~ $ ruby echo.rb -sv
    [85201:INFO] 2010-12-31 23:48:09 :: Starting server on 0.0.0.0:9000. Watch out for stones.

We should have an echo server running on port 9000. We can query using curl:

    dj2@titania ~ $ curl "localhost:9000?echo=Calling%20Goliath"
    {
      "response": "Calling Goliath"
    }

You can also query the _/status_ endpoint.

    dj2@titania ~ $ curl "localhost:9000/status"
    {
      "status": "OK"
    }

***

## Help and Documentation

* [GitHub repo](https://github.com/postrank-labs/goliath)

***

## Acknowledgments

Goliath is originally cribbed from the Thin (https://github.com/macournoyer/thin) HTTP server and has
liberally borrowed the application launching code from the Sinatra (https://github.com/bmizerany/sinatra)
framework.
