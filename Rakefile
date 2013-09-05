# -*-ruby-*-
require 'rubygems'
require 'bundler/setup'

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

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification; see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'right_git'
  gem.homepage = 'https://github.com/rightscale/right_git'
  gem.license = 'MIT'
  gem.summary = %Q{Reusable Git repository management code.}
  gem.description = %Q{An assortment of git-related classes created by RightScale.}
  gem.email = 'support@rightscale.com'
  gem.authors = ['Tony Spataro', 'Scott Messier']
  gem.rubygems_version = '1.3.7'
  gem.files.exclude 'Gemfile*'
  gem.files.exclude 'right_git.rconf'
  gem.files.exclude 'spec/**/*'
end

Jeweler::RubygemsDotOrgTasks.new

CLEAN.include('pkg')
