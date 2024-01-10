#!/usr/bin/env sh

set -e

cd "${REDMINE_DIR:-/usr/src/redmine}"

echo "=== Run tests"
echo "CHROMIUM_BIN=${CHROMIUM_BIN}"

bundle exec ruby plugins/redmine_git_mirror/test/all.rb
