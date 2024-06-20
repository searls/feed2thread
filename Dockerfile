FROM ruby:3.3.2-alpine

WORKDIR /srv
COPY Gemfile Gemfile.lock feed2thread.gemspec ./
COPY lib/feed2thread/version.rb lib/feed2thread/
RUN apk update && \
    apk add autoconf bash git gcc make musl-dev && \
    bundle install && \
    apk del --purge --rdepends git gcc autoconf make musl-dev
ADD . .
VOLUME /config
CMD ["--config", "/config/feed2thread.yml"]
ENTRYPOINT ["/srv/bin/daemon"]
