#!/usr/bin/env bash
set -eu
# working directory
cd /yb-source

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
            exit 1
        else
            echo "PATCH APPLIED: patch: ${patch_file} applied to ${relative}"
        fi
    fi
done

# patch postgres.h
/usr/local/bin/patch_postgres_h.sh
