#!/usr/bin/env bash
set -eu

cd /yb-source

git checkout -- src/postgres/third-party-extensions/Makefile

# optionally, install extensions for compilation
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
# patch postgres.h