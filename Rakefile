require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rspec/core/rake_task'

task :default => [:spec]

desc "run spec tests"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc 'Generate RDoc documentation'
Rake::RDocTask.new(:rdoc) do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'Goliath'
  task.options = %w(--title Goliath --main README.md --line-numbers)
  task.rdoc_files.include(['lib/**/*.rb'])
  task.rdoc_files.include(['README.md', 'LICENSE'])
end

spec = eval(File.read(File.join(File.dirname(__FILE__), "goliath.gemspec")))

desc 'Generate GEM'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
