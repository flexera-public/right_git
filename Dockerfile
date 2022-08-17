FROM ruby:2.1.10 AS right_git

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libxml2 \
    libxslt-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

LABEL Name=right_git Version=0.0.1

EXPOSE 3000

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /right_git
COPY . /right_git
COPY Gemfile Gemfile.lock /right_git/

# COPY Gemfile Gemfile.lock ./
RUN bundle install

# CMD ["ruby", "rightgit.rb"]
