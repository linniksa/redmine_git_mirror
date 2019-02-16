ARG VERSION

FROM redmine:$VERSION

ENV RAILS_ENV=test

RUN apt-get update -y && apt-get install -y build-essential

RUN cd /usr/src/redmine && bundle install --with test

COPY entry-point.sh /
COPY run-tests.sh /usr/local/bin/tests-run

ENTRYPOINT ["/entry-point.sh"]
CMD ["tests-run"]
