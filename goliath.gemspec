Gem::Specification.new do |s|
  s.name = 'goliath'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.authors = ['dan sinclair']
  s.email = ['dj2@everburning.com']
  s.homepage = 'http://labs.postrank.com'
  s.summary = 'Framework for writting API servers'
  s.description = s.summary

  s.required_ruby_version = '>=1.9.2'

  s.add_dependency 'eventmachine', '>=0.12'
  s.add_dependency 'em-synchrony'

  s.add_dependency 'async-rack' # :git => "git://github.com/dj2/async-rack.git"
  s.add_dependency 'rack'
  s.add_dependency 'rack-contrib'
  s.add_dependency 'rack-respond_to'

  s.add_dependency 'log4r'
  s.add_dependency 'yajl-ruby'
  s.add_dependency 'query_string_parser'

  s.add_development_dependency 'rspec'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end