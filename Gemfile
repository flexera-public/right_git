# NOTE: do not include gemspec in its Gemfile; this is a Jewelerized
# project and gemspec-in-gemfile is not appropriate. It causes a loop in the dependency
# solver and Jeweler ends up generating a needlessly large gemspec.

source 'http://s3.amazonaws.com/rightscale_rightlink_gems_dev'
source 'https://rubygems.org'

# DO NOT add gemspec to this file because it breaks Jeweler's .gemspec generation

# Runtime dependencies of RightGit
gem "right_support", [">= 2.8.10", "< 3.0.0"]

# Gems used during RightGit development that should be called out in the gemspec
group :development do
  gem "rake", [">= 0.8.7", "< 0.10"]
  gem 'jeweler', '~> 1.8.3'
  gem 'nokogiri', '1.5.6'  # locked for mswin32 friendliness
end

# Gems that are only used locally by this repo to run tests and should NOT be called out in the
# gemspec.
group :test do
  gem "rspec", [">= 1.3", "< 3.0"]
  gem "flexmock", "~> 0.8.7", :require => nil
  gem "ruby-debug", ">= 0.10", :platforms => :ruby_18
  gem "ruby-debug19", ">= 0.11.6", :platforms => :ruby_19
  if RUBY_PLATFORM =~ /mswin/
    gem "json", "1.4.6"  # locked for mswin32 friendliness
  end
end
