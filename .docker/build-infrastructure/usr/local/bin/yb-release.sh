#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source

/usr/local/bin/apply-patches.sh

[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}

# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz

# create the release archive
./yb_release --build_archive --build=release --force --keep_tmp_dir \
    --save_release_path_to_file=/yb-source/build/latest-release

mv $(cat /yb-source/build/latest-release) /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz
# done
echo "Your build is available in /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz"
