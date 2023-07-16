#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source
# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-*.tar.gz

# patches:

# https://github.com/yugabyte/yugabyte-db/issues/18260
git checkout -- python/yugabyte/library_packager.py
git apply /patches/python/yugabyte/library_packager.py.diff

# create the release archive
./yb_release --build_archive --build=release --force --keep_tmp_dir

# move to a well known location
mv /yb-source/build/yugabyte-*.tar.gz /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz

# done
echo "Your build is available in /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz"
