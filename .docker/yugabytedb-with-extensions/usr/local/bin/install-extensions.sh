#!/usr/bin/env bash

pg_config_dir=$(dirname $(realpath $(which ysqlsh)))
yb_root=$(dirname $(dirname "${pg_config_dir}"))
pkglibdir=$("${pg_config_dir}/pg_config" --pkglibdir)
sharedir=$("${pg_config_dir}/pg_config" --sharedir)
ext_directory=/extensions

echo "Installing extensions:"
echo " -> pg_config directory: ${pg_config_dir}"
echo " -> yugabyte root directory: ${yb_root}"
echo " -> pkglibdir: ${pkglibdir}"
echo " -> shareddir: ${shareddir}"

for d in ${ext_directory}/*/ ; do
    extension_name=$(basename "$d")
    echo "Installing extension: ${extension_name}"
    cp -v "${d}/${extension_name}.so" "${pkglibdir}"
    cp -v "${d}/extension/${extension_name}.control" "${sharedir}/extension"
    cp -v "${d}/extension/"*.sql "${sharedir}/extension"
done

"${yb_root}/bin/post_install.sh" -e