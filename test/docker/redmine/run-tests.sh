#!/usr/bin/env sh

echo "=== Run tests"
bundle exec ruby plugins/redmine_git_mirror/test/all.rb
