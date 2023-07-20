#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source

git reset --hard
git checkout "${YB_SOURCE_VERSION}"

/usr/local/bin/apply-patches.sh
/usr/local/bin/apply-extensions.sh

# rebuild extensions only:
[ -n "${YB_CONFIGURED_COMPILER_TYPE}" ] && export YB_COMPILER_TYPE=${YB_CONFIGURED_COMPILER_TYPE}
[ -n "${YB_CONFIGURED_COMPILER_ARCH}" ] && export YB_TARGET_ARCH=${YB_CONFIGURED_COMPILER_ARCH}

export CLEAN_THIRD_PARTY_FLAG=
if [ -f /yb-source/build/latest_build_root ]; then
    echo "Previous build discovered, discovering third-party directory..."
    latest_build_root=$(cat /yb-source/build/latest_build_root)
    third_party_dir_file="${latest_build_root}/thirdparty_path.txt"
    if [ ! -f "${third_party_dir_file}" ]; then
        echo "Warning: no ${third_party_dir_file}, cannot discover third-party directory"
    else
        latest_thirdparty_dir=$(cat "${third_party_dir_file}")
        if [ ! -d "${latest_thirdparty_dir}" ]; then
            echo "Warning: no ${latest_thirdparty_dir} directory"
        else
            export YB_THIRDPARTY_DIR="${latest_thirdparty_dir}"
            echo "Third-party directory at ${YB_THIRDPARTY_DIR} is okay, going to clean third-party"
            export CLEAN_THIRD_PARTY_FLAG="--clean-thirdparty"
        fi
    fi
fi

./yb_build.sh release --force ${CLEAN_THIRD_PARTY_FLAG}
# done
echo "Your rebuild of YugabyteDB third-party for ${YB_SOURCE_VERSION} is complete"
