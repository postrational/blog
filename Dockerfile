FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  ruby \
  ruby-dev \
  git \
  locales \
  && apt-get clean autoclean && apt-get autoremove -y

# Set locale to UTF8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Copy blog code to /srv
COPY . /srv/karzyn_octopress
WORKDIR /srv/karzyn_octopress

# Install Ruby dependencies
RUN gem install bundler:2.0.1
RUN bundle install
