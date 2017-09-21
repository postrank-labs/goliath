# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'goliath/version'

Gem::Specification.new do |s|
  s.name = 'goliath'
  s.version = Goliath::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['dan sinclair', 'Ilya Grigorik']
  s.email = ['dj2@everburning.com', 'ilya@igvita.com']
  s.homepage = 'http://goliath.io/'
  s.summary = 'Async framework for writing API servers'
  s.description = s.summary

  s.required_ruby_version = '>=2.1.0'

  s.add_dependency 'eventmachine', '>= 1.0.0.beta.4'
  s.add_dependency 'em-synchrony', '>= 1.0.0'
  s.add_dependency 'em-websocket', '0.3.8'
  s.add_dependency 'http_parser.rb', '>= 0.6.0'
  s.add_dependency 'log4r'
  s.add_dependency 'einhorn'

  s.add_dependency 'rack', '>=1.2.2'
  s.add_dependency 'rack-contrib'
  s.add_dependency 'rack-respond_to'
  s.add_dependency 'async-rack'
  s.add_dependency 'multi_json'

  s.add_development_dependency 'rake', '>=0.8.7'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'em-http-request', '>=1.0.0'
  s.add_development_dependency 'em-mongo', '~> 0.4.0'
  s.add_development_dependency 'rack-rewrite'
  s.add_development_dependency 'multipart_body'
  s.add_development_dependency 'amqp', '>=0.7.1'
  s.add_development_dependency 'em-websocket-client'
  s.add_development_dependency 'em-eventsource'
  s.add_development_dependency 'rack', '< 2'

  s.add_development_dependency 'tilt', '>=1.2.2'
  s.add_development_dependency 'haml', '>=3.0.25'
  s.add_development_dependency 'yard'

  s.add_development_dependency 'guard', '~> 2.0'
  s.add_development_dependency 'guard-rspec', '~> 4.0'
  s.add_development_dependency 'listen', '~> 2.0'

  if RUBY_PLATFORM != 'java'
    s.add_development_dependency 'yajl-ruby'
    s.add_development_dependency 'bluecloth'
    s.add_development_dependency 'bson_ext'
  else
    s.add_development_dependency 'json-jruby'
    s.add_development_dependency 'maruku'
  end

  if RUBY_PLATFORM.include?('darwin')
    s.add_development_dependency 'growl', '~> 1.0.3'
    s.add_development_dependency 'rb-fsevent'
  end

  ignores = File.readlines(".gitignore").grep(/\S+/).map {|i| i.chomp }.map {|i| File.directory?(i) ? i.sub(/\/?$/, '/*') : i }
  dotfiles = [".gemtest", ".gitignore", ".rspec", ".yardopts"]

  s.files = Dir["**/*"].reject {|f| File.directory?(f) || ignores.any? {|i| File.fnmatch(i, f) } } + dotfiles
  s.test_files = s.files.grep(/^spec\//)
  s.require_paths = ['lib']
end
