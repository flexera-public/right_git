# NOTE: do not include gemspec in its Gemfile; this is a Jewelerized
# project and gemspec-in-gemfile is not appropriate. It causes a loop in the dependency
# solver and Jeweler ends up generating a needlessly large gemspec.

source 'https://rubygems.org'

gemspec

# Gems used during RightGit development that should be called out in the gemspec
group :development do
  gem 'rake', '< 12'

  # debuggers
  gem 'pry'
  gem 'pry-byebug'
end

# Gems that are only used locally by this repo to run tests and should NOT be called out in the
# gemspec.
group :test do
  gem 'rspec',    '~> 2.0'
  gem 'flexmock', '~> 0.8.7', :require => nil
  gem 'simplecov', require: false
end
