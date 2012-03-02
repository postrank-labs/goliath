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

namespace :issues do
  desc "run closed issue tests"
  RSpec::Core::RakeTask.new(:closed) do |t|
    t.pattern = 'spec/issues/*_spec.rb'
    t.rspec_opts = %w{--tag ~status:open}
  end
  desc "run open issue tests"
  RSpec::Core::RakeTask.new(:open) do |t|
    t.pattern = 'spec/issues/*_spec.rb'
    t.rspec_opts = %w{--tag ~status:closed}
  end
  desc "run all issue tests"
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = 'spec/issues/*_spec.rb'
  end
end

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'LICENSE']
  t.options = ['--main', 'README.md', '--no-private']
end
