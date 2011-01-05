require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rspec/core/rake_task'

CLEAN.include %w(**/*.{o,bundle,so,obj,lib,log} ext/*/Makefile ext/*/conftest.dSYM)

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/goliath_parser' do
    target = "parser.c"
    File.unlink(target) if File.exist?(target)
    sh "ragel parser.rl -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist?(target)
  end
end

desc "Compile the parser"
task :build do
  Dir.chdir 'ext/goliath_parser' do
    sh "ruby extconf.rb"
    sh "make"
  end
end

task :default => [:spec]

desc "run spec tests"
RSpec::Core::RakeTask.new('spec') do |t|
  t.rspec_opts = ['-I', 'ext']
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
