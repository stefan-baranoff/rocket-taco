FROM ruby

RUN mkdir /app
ADD Gemfile /app/Gemfile
RUN cd app; bundle install
ADD app /app

WORKDIR /app

CMD ruby scripts/reset_taco_quotas.rb & ruby server.rb
