#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source
# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-*.tar.gz

# patches:

patches_base=/patches/
for patch_file in $(find ${patches_base} -type f); do
    if [[ $patch_file == *.diff ]]; then
        relative=$(echo $patch_file | sed 's!'${patches_base}'!!')
        [[ $relative == /* ]] && relative=${relative:1}
        relative=${relative/%?????/}
        git checkout -- "${relative}"
        git apply "${patch_file}"
        if [ $? -gt 0 ]; then
            echo "ERROR: failed applying patch: ${patch_file} to ${relative}"
        else
            echo "PATCH APPLIED: patch: ${patch_file} applied to ${relative}"
        fi
    fi
done

[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}

# create the release archive
./yb_release --build_archive --build=release --force --keep_tmp_dir

# move to a well known location
mv /yb-source/build/yugabyte-*.tar.gz /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz

# done
echo "Your build is available in /yb-source/build/yugabyte-${YB_RELEASE_VERSION}.tar.gz"
