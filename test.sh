#!/bin/bash
# Setup and run extension tests. This script should be run in a _clean_ CKAN
# environment. e.g.:
#
#     $ docker-compose run --rm app ./test.sh
#

set -o errexit
set -o pipefail

# Wrapper for paster/ckan.
# CKAN 2.9 replaces paster with ckan CLI. This wrapper abstracts which comand
# is called.
#
# In order to keep the parsing simple, the first argument MUST be
# --plugin=plugin-name. The config option -c is assumed to be
# test.ini because the argument ordering matters to paster and
# ckan, and again, we want to keep the parsing simple.
function ckan_wrapper () {
  if command -v ckan > /dev/null; then
    shift  # drop the --plugin= argument
    ckan -c test.ini "$@"
  else
    paster "$@" -c test.ini
  fi
}

while ! psql --host=postgres --username=postgres --command="CREATE USER ckan_default WITH PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE;"; do
  echo Retrying in 5 seconds...
  sleep 5
done


createdb --encoding=utf-8 --host=postgres --username=postgres --owner=ckan_default ckan_test
psql --host=postgres --username=postgres --command="CREATE USER datastore_write WITH PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE;"
psql --host=postgres --username=postgres --command="CREATE USER datastore_read WITH PASSWORD 'pass' NOSUPERUSER NOCREATEDB NOCREATEROLE;"
createdb --encoding=utf-8 --host=postgres --username=postgres --owner=datastore_write datastore_test

psql --host=postgres --username=postgres -d ckan_test --command="ALTER ROLE ckan_default WITH superuser;"
psql --host=postgres --username=postgres -d ckan_test --command="CREATE EXTENSION postgis;"

#. /usr/lib/python3.8/venv/scripts/common/activate
#cd /app
#python3 setup.py install
#sudo service apache2 restart

# Database is listening, but still unavailable. Just keep trying...
# while ! ckan_wrapper --plugin=ckan db init; do 
#   echo Retrying in 5 seconds...
#   sleep 5
# done
# 
# ckan_wrapper --plugin=ckanext-harvest harvester initdb
ckan_wrapper --plugin=ckanext-spatial spatial initdb

pytest --ckan-ini=test.ini --cov=ckanext.spatial --cov-report=xml --cov-append --disable-warnings ckanext/spatial/tests
