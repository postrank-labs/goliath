Gem::Specification.new do |s|
  s.name = 'goliath'
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.authors = ['dan sinclair']
  s.email = ['dj2@everburning.com']
  s.homepage = 'http://labs.postrank.com'
  s.summary = 'Framework for writting API servers'
  s.description = s.summary

  s.add_dependency 'eventmachine', '>=0.12'

  s.add_development_dependency 'rspec'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end