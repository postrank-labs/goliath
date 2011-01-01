require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'rake/clean'
require 'rake/gempackagetask'

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
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
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
