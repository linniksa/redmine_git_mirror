#!/usr/bin/env sh

set -e

cd "${REDMINE_DIR:-/usr/src/redmine}"

echo "=== Migrating Database"
rake db:create db:migrate redmine:plugins:migrate RAILS_ENV=test
