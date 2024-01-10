#!/usr/bin/env sh

set -e

cd "${REDMINE_DIR:-/usr/src/redmine}"

echo "
test:
  adapter: sqlite3
  encoding: utf8
  database: ${REDMINE_DIR:-/usr/src/redmine}/test.db
" > config/database.yml

echo "=== Installing dependencies"
bundle install --jobs 4 > /dev/null
