FROM ruby

RUN mkdir /app
ADD Gemfile /app/Gemfile
RUN cd app; bundle install
