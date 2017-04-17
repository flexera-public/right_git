# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'right_git/version'

Gem::Specification.new do |spec|
  spec.name = 'right_git'
  spec.version = ::RightGit::VERSION

  spec.require_paths = ['lib']
  spec.authors = ['Tony Spataro', 'Scott Messier']
  spec.description = 'An assortment of git-related classes created by RightScale.'
  spec.email = "support@rightscale.com"

  spec.extra_rdoc_files = [
    'CHANGELOG.rdoc',
    'LICENSE',
    'README.rdoc'
  ]
  spec.files = `git ls-files -z`.split("\x0").select { |f| f.match(%r{lib/|\.gemspec}) }
  spec.homepage = 'https://github.com/rightscale/right_git'
  spec.license = 'MIT'
  spec.summary = 'Reusable Git repository management code.'

  spec.required_ruby_version = Gem::Requirement.new('~> 2.1')
  spec.add_runtime_dependency(%q<right_support>, ["~> 2.14"])
end
