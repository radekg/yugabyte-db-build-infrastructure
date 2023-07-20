#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source
# ensure the source code
if [ ! -d "./.git" ]; then
    echo "Checking out '${YB_REPOSITORY}'..."
    git clone "${YB_REPOSITORY}" .
else 
    echo "'${YB_REPOSITORY}' already checked out..."
fi

/usr/local/bin/apply-patches.sh
/usr/local/bin/apply-extensions.sh

# checkout the version to work with
git checkout "${YB_SOURCE_VERSION}"

# first pass compile
[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}
./yb_build.sh release
# done
echo "Your first pass build of YugabyteDB ${YB_SOURCE_VERSION} is complete"
