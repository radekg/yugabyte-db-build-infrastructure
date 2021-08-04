#!/usr/bin/env bash
YB_VERSION=${YB_VERSION:-"v2.7.2"}
cd /yb-source
yes | ./yb_release
# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-${YB_VERSION}.tar.gz
mv /yb-source/build/yugabyte-${YB_VERSION}*.tar.gz /yb-source/build/yugabyte-${YB_VERSION}.tar.gz
echo "Your build is available in /yb-source/build/yugabyte-${YB_VERSION}.tar.gz"