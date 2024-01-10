#!/usr/bin/env bash
set -e

TEST_DIR=$(cd "$(dirname $0)" && echo $PWD)

compose () {
  cd ${TEST_DIR} && docker compose "$@"
}

compose build
compose run --rm redmine "$@"
