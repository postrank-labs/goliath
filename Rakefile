require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/rdoctask'
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
