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

  s.add_dependency 'eventmachine', '>= 1.0.0.beta.3'
  s.add_dependency 'em-synchrony', '>= 0.3.0.beta.1'
  s.add_dependency 'http_parser.rb'
  s.add_dependency 'log4r'

  s.add_dependency 'rack', '>=1.2.2'
  s.add_dependency 'rack-contrib'
  s.add_dependency 'rack-respond_to'
  s.add_dependency 'async-rack'
  s.add_dependency 'multi_json'

  s.add_development_dependency 'rspec', '>2.0'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'em-http-request', '>= 1.0.0.beta.1'
  s.add_development_dependency 'em-mongo'
  s.add_development_dependency 'yajl-ruby'
  s.add_development_dependency 'rack-rewrite'
  s.add_development_dependency 'multipart_body'
  s.add_development_dependency 'amqp', '>=0.7.1'

  s.add_development_dependency 'tilt', '>=1.2.2'
  s.add_development_dependency 'haml', '>=3.0.25'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'bluecloth'

  ignores = File.readlines(".gitignore").grep(/\S+/).map {|s| s.chomp }
  dotfiles = [".gemtest", ".gitignore", ".rspec", ".yardopts"]

  s.files = Dir["**/*"].reject {|f| File.directory?(f) || ignores.any? {|i| File.fnmatch(i, f) } } + dotfiles
  s.test_files = s.files.grep(/^spec\//)
  s.require_paths = ['lib']
end
