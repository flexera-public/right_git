# -*-ruby-*-
require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rake'
require 'rdoc/task'
require 'rubygems/package_task'

require 'rake/clean'
require 'rspec/core/rake_task'

desc "Run unit tests"
task :default => :spec

desc "Run unit tests"
RSpec::Core::RakeTask.new do |t|
  t.pattern = Dir['**/*_spec.rb']
end

desc 'Generate documentation for the right_git gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'RightGit'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('spec/**/*')
end

CLEAN.include('pkg')
