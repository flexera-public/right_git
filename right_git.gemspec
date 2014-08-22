# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: right_git 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "right_git"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Tony Spataro", "Scott Messier"]
  s.date = "2014-08-20"
  s.description = "An assortment of git-related classes created by RightScale."
  s.email = "support@rightscale.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".rspec",
    "CHANGELOG.rdoc",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/right_git.rb",
    "lib/right_git/git.rb",
    "lib/right_git/git/belongs_to_repository.rb",
    "lib/right_git/git/branch.rb",
    "lib/right_git/git/branch_collection.rb",
    "lib/right_git/git/commit.rb",
    "lib/right_git/git/repository.rb",
    "lib/right_git/git/tag.rb",
    "lib/right_git/shell.rb",
    "lib/right_git/shell/default.rb",
    "lib/right_git/shell/interface.rb",
    "right_git.gemspec"
  ]
  s.homepage = "https://github.com/rightscale/right_git"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Reusable Git repository management code."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<right_support>, [">= 2.8.10"])
      s.add_development_dependency(%q<rake>, [">= 0.8.7"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<debugger>, [">= 1.6.6"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<pry-byebug>, [">= 0"])
    else
      s.add_dependency(%q<right_support>, [">= 2.8.10"])
      s.add_dependency(%q<rake>, [">= 0.8.7"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<debugger>, [">= 1.6.6"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<pry-byebug>, [">= 0"])
    end
  else
    s.add_dependency(%q<right_support>, [">= 2.8.10"])
    s.add_dependency(%q<rake>, [">= 0.8.7"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<debugger>, [">= 1.6.6"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<pry-byebug>, [">= 0"])
  end
end

