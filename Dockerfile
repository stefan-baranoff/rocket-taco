FROM ruby

COPY ca-bundle.trust.crt /tmp
ENV SSL_CERT_FILE=/tmp/ca-bundle.trust.crt

RUN mkdir /app
ADD Gemfile /app/Gemfile
RUN cd app; bundle install
ADD app /app

WORKDIR /app

CMD ruby scripts/reset_taco_quotas.rb & ruby server.rb
