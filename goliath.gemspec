# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'goliath/version'

Gem::Specification.new do |s|
  s.name = 'goliath'
  s.version = Goliath::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['dan sinclair', 'Ilya Grigorik']
  s.email = ['dj2@everburning.com', 'ilya@igvita.com']
  s.homepage = 'http://labs.postrank.com/'
  s.summary = 'Framework for writing API servers'
  s.description = s.summary

  s.required_ruby_version = '>=1.9.2'

  s.add_dependency 'eventmachine', '>= 1.0.0.beta.1'
  s.add_dependency 'em-synchrony'
  s.add_dependency 'http_parser.rb'
  s.add_dependency 'log4r'

  s.add_dependency 'rack'
  s.add_dependency 'rack-contrib'
  s.add_dependency 'rack-respond_to'
  s.add_dependency 'async-rack'
  s.add_dependency 'multi_json'

  s.add_development_dependency 'rspec', '>2.0'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'em-http-request', '>= 1.0.0.beta.1'
  s.add_development_dependency 'yajl-ruby'

  s.add_development_dependency 'yard'
  s.add_development_dependency 'bluecloth'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end
