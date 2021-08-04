#!/usr/bin/env bash

YB_VERSION=${YB_VERSION:-"v2.7.2"}

# reset the Makefile of the third-party extensions
git checkout -- src/postgres/third-party-extensions/Makefile

git checkout "${YB_VERSION}"

extra_extensions=""
count=$(find /extensions/ -maxdepth 1 -type d | grep -v '^/extensions/$' | wc -l)
if [ $count -ne 0 ]; then
    for d in /extensions/*/ ; do
        ext_name=$(basename "$d")
        echo "Discovered an extension to add: '${ext_name}'"
        extra_extensions="$extra_extensions $ext_name"
        rm -rf "src/postgres/third-party-extensions/${ext_name}"
        cp -v -r "$d" src/postgres/third-party-extensions/
    done
fi

if [ -z "${extra_extensions}" ]; then
    echo "There were no extra extensions to compile with..."
else
    echo "Appending '${extra_extensions}' to src/postgres/third-party-extensions/Makefile"
    sed -i "1{s/$/${extra_extensions}/}" src/postgres/third-party-extensions/Makefile
fi

./yb_build.sh release
yes | ./yb_release

# remove old build, if exists...
rm -rf /yb-source/build/yugabyte-${YB_VERSION}.tar.gz
mv /yb-source/build/yugabyte-${YB_VERSION}*.tar.gz /yb-source/build/yugabyte-${YB_VERSION}.tar.gz

echo "Your build is available in /yb-source/build/yugabyte-${YB_VERSION}.tar.gz"