# NOTE: do not include gemspec in its Gemfile; this is a Jewelerized
# project and gemspec-in-gemfile is not appropriate. It causes a loop in the dependency
# solver and Jeweler ends up generating a needlessly large gemspec.

source 'https://rubygems.org'

# DO NOT add gemspec to this file because it breaks Jeweler's .gemspec generation

# Runtime dependencies of RightGit
gem 'right_support', '>= 2.8.10'

# Gems used during RightGit development that should be called out in the gemspec
group :development do
  gem 'rake', '>= 0.8.7'
  gem 'jeweler', '~> 2.0'

  gem 'right_develop', '~> 1.0'

  # debuggers
  gem 'debugger', '>= 1.6.6', :platforms => [:ruby_19, :ruby_20]
  gem 'pry', :platforms => [:ruby_21]
  gem 'pry-byebug', :platforms => [:ruby_21]
end

# Gems that are only used locally by this repo to run tests and should NOT be called out in the
# gemspec.
group :test do
  gem 'rspec',    '~> 2.0'
  gem 'flexmock', '~> 0.8.7', :require => nil
end
