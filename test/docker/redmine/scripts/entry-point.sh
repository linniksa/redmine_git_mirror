#!/usr/bin/env sh

set -e

. /configure.sh
. /migrate-db.sh

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo " Ruby: $(ruby -v)"
echo " Rails: $(./bin/rails runner 'puts Rails::VERSION::STRING')"
echo " Redmine: $(./bin/rails runner 'puts Redmine::VERSION.to_s')"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

exec "$@"
