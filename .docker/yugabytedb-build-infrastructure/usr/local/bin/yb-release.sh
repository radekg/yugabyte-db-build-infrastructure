#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source
# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-*.tar.gz
# create the release archive
yes | ./yb_release
# move to a well known location
mv /yb-source/build/yugabyte-*.tar.gz /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz
# done
echo "Your build is available in /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz"