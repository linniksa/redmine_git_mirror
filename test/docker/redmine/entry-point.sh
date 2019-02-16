#!/usr/bin/env sh

set -e

cd /usr/src/redmine

echo "
test:
  adapter: sqlite3
  encoding: utf8
  database: /usr/src/redmine/test.db
" > config/database.yml

cp Gemfile.lock.sqlite3 Gemfile.lock

echo "=== Installing dependencies"
bundle install --with test > /dev/null

echo "=== Migrating Database"
rake db:create db:migrate redmine:plugins:migrate RAILS_ENV=test > /dev/null

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Ruby:" `ruby -v`
echo " Rails:" `./bin/rails runner "puts Rails::VERSION::STRING"`
echo " Redmine:" `./bin/rails runner "puts Redmine::VERSION.to_s"`
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

exec "$@"
