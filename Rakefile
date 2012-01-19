require 'bundler'
Bundler::GemHelper.install_tasks

require 'yard'
require 'rspec/core/rake_task'
require 'rake/testtask'

task :default => [:test]
task :test => [:spec, :unit]

desc "run the unit test"
Rake::TestTask.new(:unit) do |t|
   t.libs << "test"
   t.test_files = FileList['test/**/*_test.rb']
   t.verbose = true
end

desc "run spec tests"
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'LICENSE']
  t.options = ['--main', 'README.md', '--no-private']
end
