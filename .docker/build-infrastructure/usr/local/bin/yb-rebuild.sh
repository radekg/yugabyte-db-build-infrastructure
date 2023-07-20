#!/usr/bin/env bash
set -eu

# cleanup any potential previous runs:
rm -rfv /tmp/yb_test.tmp*

# working directory
cd /yb-source

git reset --hard
git checkout "${YB_SOURCE_VERSION}"

/usr/local/bin/apply-patches.sh
/usr/local/bin/apply-extensions.sh

# recompile
[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}
./yb_build.sh release
# done
echo "Your rebuild of YugabyteDB ${YB_SOURCE_VERSION} is complete"
